import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const String databaseName = 'station_service.db';
  static const int databaseVersion = 14;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await databasePath;
    return await openDatabase(
      path,
      version: databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<String> get databasePath async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, databaseName);
  }

  Future<void> closeDatabase() async {
    if (_database == null) return;
    await _database!.close();
    _database = null;
  }

  Future<String?> replaceDatabaseFromFile(String sourcePath) async {
    final path = await databasePath;
    await closeDatabase();

    String? safetyCopyPath;
    final currentFile = File(path);
    if (await currentFile.exists()) {
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      safetyCopyPath = '$path.before-cloud-restore-$timestamp';
      await currentFile.copy(safetyCopyPath);
    }

    await deleteDatabase(path);
    await File(sourcePath).copy(path);
    await _deleteSidecarFiles(path);
    _database = await _initDatabase();
    return safetyCopyPath;
  }

  Future<void> _deleteSidecarFiles(String path) async {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final sidecar = '$path$suffix';
      final file = File(sidecar);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        name TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE fuels(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        supplier TEXT NOT NULL DEFAULT 'N/A',
        pricePerLiter REAL NOT NULL,
        stockLiters REAL NOT NULL,
        lowStockThreshold REAL NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE pumps(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        fuelId INTEGER NOT NULL,
        status TEXT NOT NULL,
        meterReading REAL NOT NULL,
        FOREIGN KEY(fuelId) REFERENCES fuels(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE pump_nozzles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pumpId INTEGER NOT NULL,
        name TEXT NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY(pumpId) REFERENCES pumps(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE sales_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        openedAt TEXT NOT NULL,
        closedAt TEXT,
        status TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE session_pompistes(
        sessionId INTEGER NOT NULL,
        pompisteId INTEGER NOT NULL,
        PRIMARY KEY(sessionId, pompisteId),
        FOREIGN KEY(sessionId) REFERENCES sales_sessions(id),
        FOREIGN KEY(pompisteId) REFERENCES pompistes(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pumpId INTEGER NOT NULL,
        fuelId INTEGER NOT NULL,
        nozzleId INTEGER,
        liters REAL NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        clientId INTEGER,
        sessionId INTEGER,
        FOREIGN KEY(pumpId) REFERENCES pumps(id),
        FOREIGN KEY(fuelId) REFERENCES fuels(id),
        FOREIGN KEY(nozzleId) REFERENCES pump_nozzles(id),
        FOREIGN KEY(clientId) REFERENCES clients(id),
        FOREIGN KEY(sessionId) REFERENCES sales_sessions(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE product_sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        quantity REAL NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        sessionId INTEGER,
        FOREIGN KEY(productId) REFERENCES sales_products(id),
        FOREIGN KEY(sessionId) REFERENCES sales_sessions(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cardNumber TEXT,
        balance REAL NOT NULL,
        credit REAL NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE stock_movements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fuelId INTEGER NOT NULL,
        type TEXT NOT NULL,
        liters REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY(fuelId) REFERENCES fuels(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE sales_products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        unitPrice REAL NOT NULL,
        stockQuantity REAL NOT NULL,
        lowStockThreshold REAL NOT NULL DEFAULT 5
      );
    ''');

    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stationName TEXT,
        stationAddress TEXT,
        phone TEXT,
        backupPath TEXT,
        adminEmail TEXT,
        logoPath TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE suppliers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        phone TEXT,
        paymentType TEXT NOT NULL,
        unitPrice REAL NOT NULL DEFAULT 0,
        quantity REAL NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'nombre',
        totalAmount REAL NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motif TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        paymentType TEXT NOT NULL,
        supplierId INTEGER,
        FOREIGN KEY(supplierId) REFERENCES suppliers(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE choice_options(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        value TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE pompistes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        hireDate TEXT NOT NULL,
        status TEXT NOT NULL
      );
    ''');

    await _createActivityLogsTable(db);
    await _createActivityLogTriggers(db);
    // Only insert choice options and users, not other default data
    await _insertDefaultUsers(db);
    await _insertDefaultChoices(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE pompistes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          address TEXT,
          hireDate TEXT NOT NULL,
          status TEXT NOT NULL
        );
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE pump_nozzles(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pumpId INTEGER NOT NULL,
          name TEXT NOT NULL,
          status TEXT NOT NULL,
          FOREIGN KEY(pumpId) REFERENCES pumps(id)
        );
      ''');
      final pumps = await db.query('pumps', columns: ['id']);
      for (final pump in pumps) {
        final pumpId = pump['id'] as int;
        await _createDefaultNozzles(db, pumpId);
      }
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales_sessions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          code TEXT NOT NULL UNIQUE,
          openedAt TEXT NOT NULL,
          closedAt TEXT,
          status TEXT NOT NULL
        );
      ''');
      final columns = await db.rawQuery("PRAGMA table_info('sales')");
      final hasSessionId = columns.any((col) => col['name'] == 'sessionId');
      if (!hasSessionId) {
        await db.execute('ALTER TABLE sales ADD COLUMN sessionId INTEGER;');
      }
    }

    if (oldVersion < 5) {
      final columns = await db.rawQuery("PRAGMA table_info('fuels')");
      final hasSupplier = columns.any((col) => col['name'] == 'supplier');
      if (!hasSupplier) {
        await db.execute(
          "ALTER TABLE fuels ADD COLUMN supplier TEXT NOT NULL DEFAULT 'N/A';",
        );
      }
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales_products(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          unitPrice REAL NOT NULL,
          stockQuantity REAL NOT NULL,
          lowStockThreshold REAL NOT NULL DEFAULT 5
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS session_pompistes(
          sessionId INTEGER NOT NULL,
          pompisteId INTEGER NOT NULL,
          PRIMARY KEY(sessionId, pompisteId),
          FOREIGN KEY(sessionId) REFERENCES sales_sessions(id),
          FOREIGN KEY(pompisteId) REFERENCES pompistes(id)
        );
      ''');
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS product_sales(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          productId INTEGER NOT NULL,
          quantity REAL NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          sessionId INTEGER,
          FOREIGN KEY(productId) REFERENCES sales_products(id),
          FOREIGN KEY(sessionId) REFERENCES sales_sessions(id)
        );
      ''');
    }

    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS suppliers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          phone TEXT,
          paymentType TEXT NOT NULL,
          credit REAL NOT NULL DEFAULT 0
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          motif TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          paymentType TEXT NOT NULL,
          supplierId INTEGER,
          FOREIGN KEY(supplierId) REFERENCES suppliers(id)
        );
      ''');
    }

    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS choice_options(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          value TEXT NOT NULL
        );
      ''');
      final supplierCols = await db.rawQuery("PRAGMA table_info('suppliers')");
      final hasUnitPrice = supplierCols.any(
        (col) => col['name'] == 'unitPrice',
      );
      if (!hasUnitPrice) {
        await db.execute(
          'ALTER TABLE suppliers ADD COLUMN unitPrice REAL NOT NULL DEFAULT 0;',
        );
      }
      final hasQuantity = supplierCols.any((col) => col['name'] == 'quantity');
      if (!hasQuantity) {
        await db.execute(
          'ALTER TABLE suppliers ADD COLUMN quantity REAL NOT NULL DEFAULT 0;',
        );
      }
      final hasUnit = supplierCols.any((col) => col['name'] == 'unit');
      if (!hasUnit) {
        await db.execute(
          "ALTER TABLE suppliers ADD COLUMN unit TEXT NOT NULL DEFAULT 'nombre';",
        );
      }
      final hasTotalAmount = supplierCols.any(
        (col) => col['name'] == 'totalAmount',
      );
      if (!hasTotalAmount) {
        await db.execute(
          'ALTER TABLE suppliers ADD COLUMN totalAmount REAL NOT NULL DEFAULT 0;',
        );
      }
      final countRows = await db.rawQuery(
        'SELECT COUNT(*) as c FROM choice_options',
      );
      final count = (countRows.first['c'] as num?)?.toInt() ?? 0;
      if (count == 0) {
        await _insertDefaultChoices(db);
      }
    }

    if (oldVersion < 10) {
      await _createActivityLogsTable(db);
      await _createActivityLogTriggers(db);
    }

    if (oldVersion < 11) {
      final productCols = await db.rawQuery(
        "PRAGMA table_info('sales_products')",
      );
      final hasLowStockThreshold = productCols.any(
        (col) => col['name'] == 'lowStockThreshold',
      );
      if (!hasLowStockThreshold) {
        await db.execute(
          'ALTER TABLE sales_products ADD COLUMN lowStockThreshold REAL NOT NULL DEFAULT 5;',
        );
      }
    }

    if (oldVersion < 12) {
      final settingsCols = await db.rawQuery("PRAGMA table_info('settings')");
      final hasLogoPath = settingsCols.any((col) => col['name'] == 'logoPath');
      if (!hasLogoPath) {
        await db.execute('ALTER TABLE settings ADD COLUMN logoPath TEXT;');
      }
    }

    if (oldVersion < 13) {
      final salesCols = await db.rawQuery("PRAGMA table_info('sales')");
      final hasNozzleId = salesCols.any((col) => col['name'] == 'nozzleId');
      if (!hasNozzleId) {
        await db.execute(
          'ALTER TABLE sales ADD COLUMN nozzleId INTEGER REFERENCES pump_nozzles(id);',
        );
      }
    }

    if (oldVersion < 14) {
      final settingsCols = await db.rawQuery("PRAGMA table_info('settings')");
      final hasAdminEmail = settingsCols.any(
        (col) => col['name'] == 'adminEmail',
      );
      if (!hasAdminEmail) {
        await db.execute('ALTER TABLE settings ADD COLUMN adminEmail TEXT;');
      }
    }
  }

  Future<void> _createActivityLogsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activity_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tableName TEXT NOT NULL,
        operation TEXT NOT NULL,
        recordId TEXT,
        occurredAt TEXT NOT NULL DEFAULT (datetime('now')),
        description TEXT NOT NULL
      );
    ''');
  }

  Future<void> _createActivityLogTriggers(Database db) async {
    final triggerStatements = <String>[
      '''
      CREATE TRIGGER IF NOT EXISTS trg_sales_insert
      AFTER INSERT ON sales
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'sales',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Vente carburant enregistree: fuelId=' || NEW.fuelId || ', pumpId=' || NEW.pumpId || ', litres=' || NEW.liters || ', montant=' || NEW.amount
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_sales_update
      AFTER UPDATE ON sales
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'sales',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Vente carburant modifiee: fuelId=' || NEW.fuelId || ', pumpId=' || NEW.pumpId || ', litres=' || NEW.liters || ', montant=' || NEW.amount
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_sales_delete
      AFTER DELETE ON sales
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'sales',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Vente carburant supprimee: fuelId=' || OLD.fuelId || ', pumpId=' || OLD.pumpId || ', litres=' || OLD.liters || ', montant=' || OLD.amount
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_product_sales_insert
      AFTER INSERT ON product_sales
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'product_sales',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Vente produit enregistree: productId=' || NEW.productId || ', quantite=' || NEW.quantity || ', montant=' || NEW.amount
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_product_sales_update
      AFTER UPDATE ON product_sales
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'product_sales',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Vente produit modifiee: productId=' || NEW.productId || ', quantite=' || NEW.quantity || ', montant=' || NEW.amount
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_product_sales_delete
      AFTER DELETE ON product_sales
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'product_sales',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Vente produit supprimee: productId=' || OLD.productId || ', quantite=' || OLD.quantity || ', montant=' || OLD.amount
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_stock_movements_insert
      AFTER INSERT ON stock_movements
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'stock_movements',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Mouvement stock enregistre: fuelId=' || NEW.fuelId || ', type=' || NEW.type || ', litres=' || NEW.liters
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_stock_movements_update
      AFTER UPDATE ON stock_movements
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'stock_movements',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Mouvement stock modifie: fuelId=' || NEW.fuelId || ', type=' || NEW.type || ', litres=' || NEW.liters
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_stock_movements_delete
      AFTER DELETE ON stock_movements
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'stock_movements',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Mouvement stock supprime: fuelId=' || OLD.fuelId || ', type=' || OLD.type || ', litres=' || OLD.liters
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_expenses_insert
      AFTER INSERT ON expenses
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'expenses',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Depense enregistree: motif=' || NEW.motif || ', montant=' || NEW.amount || ', paiement=' || NEW.paymentType
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_expenses_update
      AFTER UPDATE ON expenses
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'expenses',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Depense modifiee: motif=' || NEW.motif || ', montant=' || NEW.amount || ', paiement=' || NEW.paymentType
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_expenses_delete
      AFTER DELETE ON expenses
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'expenses',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Depense supprimee: motif=' || OLD.motif || ', montant=' || OLD.amount || ', paiement=' || OLD.paymentType
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_sales_sessions_insert
      AFTER INSERT ON sales_sessions
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'sales_sessions',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Session creee: code=' || NEW.code || ', statut=' || NEW.status
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_sales_sessions_update
      AFTER UPDATE ON sales_sessions
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'sales_sessions',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Session modifiee: code=' || NEW.code || ', statut=' || NEW.status
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_sales_sessions_delete
      AFTER DELETE ON sales_sessions
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'sales_sessions',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Session supprimee: code=' || OLD.code || ', statut=' || OLD.status
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_session_pompistes_insert
      AFTER INSERT ON session_pompistes
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'session_pompistes',
          'INSERT',
          CAST(NEW.sessionId AS TEXT) || ':' || CAST(NEW.pompisteId AS TEXT),
          'Pompiste assigne a session: sessionId=' || NEW.sessionId || ', pompisteId=' || NEW.pompisteId
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_session_pompistes_delete
      AFTER DELETE ON session_pompistes
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'session_pompistes',
          'DELETE',
          CAST(OLD.sessionId AS TEXT) || ':' || CAST(OLD.pompisteId AS TEXT),
          'Pompiste retire de session: sessionId=' || OLD.sessionId || ', pompisteId=' || OLD.pompisteId
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_fuels_insert
      AFTER INSERT ON fuels
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'fuels',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Carburant cree: nom=' || NEW.name || ', prix=' || NEW.pricePerLiter || ', stock=' || NEW.stockLiters
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_fuels_update
      AFTER UPDATE ON fuels
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'fuels',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Carburant modifie: nom=' || NEW.name || ', prix=' || NEW.pricePerLiter || ', stock=' || NEW.stockLiters
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_fuels_delete
      AFTER DELETE ON fuels
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'fuels',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Carburant supprime: nom=' || OLD.name
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_pumps_insert
      AFTER INSERT ON pumps
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'pumps',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Pompe creee: nom=' || NEW.name || ', fuelId=' || NEW.fuelId || ', statut=' || NEW.status
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_pumps_update
      AFTER UPDATE ON pumps
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'pumps',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Pompe modifiee: nom=' || NEW.name || ', fuelId=' || NEW.fuelId || ', statut=' || NEW.status
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_pumps_delete
      AFTER DELETE ON pumps
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'pumps',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Pompe supprimee: nom=' || OLD.name
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_pump_nozzles_insert
      AFTER INSERT ON pump_nozzles
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'pump_nozzles',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Pistolet cree: nom=' || NEW.name || ', pumpId=' || NEW.pumpId || ', statut=' || NEW.status
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_pump_nozzles_update
      AFTER UPDATE ON pump_nozzles
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'pump_nozzles',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Pistolet modifie: nom=' || NEW.name || ', pumpId=' || NEW.pumpId || ', statut=' || NEW.status
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_pump_nozzles_delete
      AFTER DELETE ON pump_nozzles
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'pump_nozzles',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Pistolet supprime: nom=' || OLD.name || ', pumpId=' || OLD.pumpId
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_clients_insert
      AFTER INSERT ON clients
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'clients',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Client cree: nom=' || NEW.name || ', solde=' || NEW.balance || ', credit=' || NEW.credit
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_clients_update
      AFTER UPDATE ON clients
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'clients',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Client modifie: nom=' || NEW.name || ', solde=' || NEW.balance || ', credit=' || NEW.credit
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_clients_delete
      AFTER DELETE ON clients
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'clients',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Client supprime: nom=' || OLD.name
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_sales_products_insert
      AFTER INSERT ON sales_products
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'sales_products',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Produit cree: nom=' || NEW.name || ', categorie=' || NEW.category || ', prix=' || NEW.unitPrice || ', stock=' || NEW.stockQuantity
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_sales_products_update
      AFTER UPDATE ON sales_products
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'sales_products',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Produit modifie: nom=' || NEW.name || ', categorie=' || NEW.category || ', prix=' || NEW.unitPrice || ', stock=' || NEW.stockQuantity
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_sales_products_delete
      AFTER DELETE ON sales_products
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'sales_products',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Produit supprime: nom=' || OLD.name || ', categorie=' || OLD.category
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_suppliers_insert
      AFTER INSERT ON suppliers
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'suppliers',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Fournisseur cree: nom=' || NEW.name || ', categorie=' || NEW.category || ', montant=' || NEW.totalAmount
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_suppliers_update
      AFTER UPDATE ON suppliers
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'suppliers',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Fournisseur modifie: nom=' || NEW.name || ', categorie=' || NEW.category || ', montant=' || NEW.totalAmount
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_suppliers_delete
      AFTER DELETE ON suppliers
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'suppliers',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Fournisseur supprime: nom=' || OLD.name || ', categorie=' || OLD.category
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_pompistes_insert
      AFTER INSERT ON pompistes
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'pompistes',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Pompiste cree: nom=' || NEW.name || ', statut=' || NEW.status
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_pompistes_update
      AFTER UPDATE ON pompistes
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'pompistes',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Pompiste modifie: nom=' || NEW.name || ', statut=' || NEW.status
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_pompistes_delete
      AFTER DELETE ON pompistes
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'pompistes',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Pompiste supprime: nom=' || OLD.name
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_users_insert
      AFTER INSERT ON users
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'users',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Utilisateur cree: username=' || NEW.username || ', role=' || NEW.role
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_users_update
      AFTER UPDATE ON users
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'users',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Utilisateur modifie: username=' || NEW.username || ', role=' || NEW.role
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_users_delete
      AFTER DELETE ON users
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'users',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Utilisateur supprime: username=' || OLD.username || ', role=' || OLD.role
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_settings_update
      AFTER UPDATE ON settings
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'settings',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Parametres modifies: station=' || COALESCE(NEW.stationName, '-') || ', telephone=' || COALESCE(NEW.phone, '-')
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_choice_options_insert
      AFTER INSERT ON choice_options
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'choice_options',
          'INSERT',
          CAST(NEW.id AS TEXT),
          'Option ajoutee: type=' || NEW.type || ', valeur=' || NEW.value
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_choice_options_update
      AFTER UPDATE ON choice_options
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'choice_options',
          'UPDATE',
          CAST(NEW.id AS TEXT),
          'Option modifiee: type=' || NEW.type || ', valeur=' || NEW.value
        );
      END;
      ''',
      '''
      CREATE TRIGGER IF NOT EXISTS trg_choice_options_delete
      AFTER DELETE ON choice_options
      BEGIN
        INSERT INTO activity_logs(tableName, operation, recordId, description)
        VALUES(
          'choice_options',
          'DELETE',
          CAST(OLD.id AS TEXT),
          'Option supprimee: type=' || OLD.type || ', valeur=' || OLD.value
        );
      END;
      ''',
    ];

    for (final statement in triggerStatements) {
      await db.execute(statement);
    }
  }

  Future<void> _insertDefaultUsers(Database db) async {
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
      'name': 'Administrateur',
    });
    await db.insert('users', {
      'username': 'kanidak',
      'password': 'bailou5625',
      'role': 'caissier',
      'name': 'Caissier',
    });
  }

  Future<void> _insertDefaultChoices(Database db) async {
    for (final payment in const [
      'Espèces',
      'Virement',
      'Mobile Money',
      'Crédit',
    ]) {
      await db.insert('choice_options', {
        'type': 'payment_type',
        'value': payment,
      });
    }
    for (final category in const ['Carburant', 'Huile', 'Gaz', 'Autre']) {
      await db.insert('choice_options', {
        'type': 'supplier_category',
        'value': category,
      });
    }
  }

  Future<void> _createDefaultNozzles(Database db, int pumpId) async {
    await db.insert('pump_nozzles', {
      'pumpId': pumpId,
      'name': 'Pistolet 1',
      'status': 'active',
    });
    await db.insert('pump_nozzles', {
      'pumpId': pumpId,
      'name': 'Pistolet 2',
      'status': 'active',
    });
  }

  Future<void> resetDatabase() async {
    final path = await databasePath;

    await closeDatabase();
    await deleteDatabase(path);
    _database = await _initDatabase();
  }
}
