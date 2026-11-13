
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => AccelerationCubit(),
      child: const MyApp(),
    ),
  );
}

abstract class AccelerationState {}

class AccelerationInitial extends AccelerationState {}

class AccelerationResult extends AccelerationState {
  final double v0;
  final double v;
  final double t;
  final double a;

  AccelerationResult({
    required this.v0,
    required this.v,
    required this.t,
    required this.a,
  });
}

class AccelerationError extends AccelerationState {
  final String message;

  AccelerationError(this.message);
}

class AccelerationCubit extends Cubit<AccelerationState> {
  AccelerationCubit() : super(AccelerationInitial());

  void calculate(String v0Text, String vText, String tText) {
    final v0 = double.tryParse(v0Text.trim());
    final v = double.tryParse(vText.trim());
    final t = double.tryParse(tText.trim());

    if (v0 == null || v == null || t == null) {
      emit(AccelerationError('Введите корректные числа'));
      return;
    }

    if (t <= 0) {
      emit(AccelerationError('Время должно быть больше 0'));
      return;
    }

    final a = (v - v0) / t;

    emit(
      AccelerationResult(
        v0: v0,
        v: v,
        t: t,
        a: a,
      ),
    );
  }

  void reset() {
    emit(AccelerationInitial());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  final _v0 = TextEditingController();
  final _v = TextEditingController();
  final _t = TextEditingController();

  bool _agree = false;
  bool _agreeError = false;

  @override
  void dispose() {
    _v0.dispose();
    _v.dispose();
    _t.dispose();
    super.dispose();
  }

  void _calculate() {
    final formOk = _formKey.currentState!.validate();

    setState(() {
      _agreeError = !_agree;
    });

    if (!formOk || !_agree) return;

    context.read<AccelerationCubit>().calculate(
          _v0.text,
          _v.text,
          _t.text,
        );
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите $fieldName';
    }

    if (double.tryParse(value.trim()) == null) {
      return 'Введите число';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расчёт ускорения'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _v0,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Начальная скорость v0 (м/с)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    _validateNumber(value, 'начальную скорость'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _v,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Конечная скорость v (м/с)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    _validateNumber(value, 'конечную скорость'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _t,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Время t (с)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final error = _validateNumber(value, 'время');

                  if (error != null) return error;

                  if (double.parse(value!.trim()) <= 0) {
                    return 'Время должно быть больше 0';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Согласен на обработку данных'),
                value: _agree,
                onChanged: (value) {
                  setState(() {
                    _agree = value ?? false;
                    _agreeError = false;
                  });
                },
              ),
              if (_agreeError)
                const Text(
                  'Необходимо согласие на обработку данных',
                  style: TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculate,
                child: const Text('Рассчитать'),
              ),
              const SizedBox(height: 24),
              BlocBuilder<AccelerationCubit, AccelerationState>(
                builder: (context, state) {
                  if (state is AccelerationInitial) {
                    return const Text(
                      'Введите данные и нажмите «Рассчитать».',
                      textAlign: TextAlign.center,
                    );
                  }

                  if (state is AccelerationError) {
                    return Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    );
                  }

                  if (state is AccelerationResult) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Результат расчёта',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('v0 = ${state.v0} м/с'),
                            Text('v = ${state.v} м/с'),
                            Text('t = ${state.t} с'),
                            const SizedBox(height: 12),
                            Text(
                              'Ускорение a = '
                              '${state.a.toStringAsFixed(2)} м/с²',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<AccelerationCubit>().reset();
                              },
                              child: const Text('Сбросить'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
