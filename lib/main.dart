import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'imc_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE imc(id INTEGER PRIMARY KEY AUTOINCREMENT, peso REAL, altura REAL, resultado TEXT)',
      );
    },
    version: 1,
  );

  runApp(MaterialApp(
    title: 'Calculadora IMC',
    home: CalculadoraIMC(database: database),
  ));
}

class CalculadoraIMC extends StatefulWidget {
  final Future<Database> database;

  const CalculadoraIMC({required this.database});

  @override
  _CalculadoraIMCState createState() => _CalculadoraIMCState();
}

class _CalculadoraIMCState extends State<CalculadoraIMC> {
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController alturaController = TextEditingController();
  String resultado = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora IMC'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Opções',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Ver resultados anteriores'),
              onTap: () {
                Navigator.pop(context); // fecha o Drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ResultadosAnterioresScreen(
                          database: widget.database)),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: pesoController,
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: alturaController,
              decoration: const InputDecoration(labelText: 'Altura (m)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => calcularIMC(widget.database),
              child: const Text('Calcular IMC'),
            ),
            const SizedBox(height: 16),
            Text(
              resultado,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> calcularIMC(Future<Database> databaseFuture) async {
    final Database database = await databaseFuture;

    double peso = double.tryParse(pesoController.text) ?? 0;
    double altura = double.tryParse(alturaController.text) ?? 0;

    if (peso > 0 && altura > 0) {
      double imc = peso / (altura * altura);
      String resultadoIMC;

      if (imc < 18.6)
        resultadoIMC = "Abaixo do peso";
      else if (imc < 25.0)
        resultadoIMC = "Peso ideal";
      else if (imc < 30.0)
        resultadoIMC = "Levemente acima do peso";
      else if (imc < 35.0)
        resultadoIMC = "Obesidade Grau I";
      else if (imc < 40.0)
        resultadoIMC = "Obesidade Grau II";
      else
        resultadoIMC = "Obesidade Grau III";

      await database.insert(
        'imc',
        {
          'peso': peso,
          'altura': altura,
          'resultado': resultadoIMC,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      setState(() {
        resultado = resultadoIMC;
      });
    } else {
      setState(() {
        resultado = '';
      });
    }
  }
}

class ResultadosAnterioresScreen extends StatelessWidget {
  final Future<Database> database;

  const ResultadosAnterioresScreen({required this.database});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados Anteriores'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getIMC(database),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final resultados = snapshot.data!;
            return ListView.builder(
              itemCount: resultados.length,
              itemBuilder: (BuildContext context, int index) {
                final resultado = resultados[index];
                return ListTile(
                  title: Text('IMC: ${resultado['resultado']}'),
                  subtitle: Text(
                      'Peso: ${resultado['peso']}kg, Altura: ${resultado['altura']}m'),
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getIMC(Future<Database> database) async {
    final Database db = await database;
    return db.query('imc');
  }
}
