# Limpio (Flutter)

App móvil de finanzas personales USD/VES — recreación en Flutter de la app Expo original.

## Requisitos

- Flutter SDK 3.x estable
- Android SDK (para build APK)

## Configuración

```bash
cd /home/axel/Code/limpio-dart
flutter pub get
```

Si faltan carpetas de plataforma o iconos:

```bash
flutter create --org com.webpack123 --project-name limpio_dart .
```

## Ejecutar

```bash
flutter run
```

## Tests y análisis

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Estructura

- `lib/screens/` — Billetera, Ingresos fijos, Papelera
- `lib/providers/` — Estado con Riverpod
- `lib/services/` — Hive (persistencia) y tasas dolarapi
- `lib/features/invoice_scan/` — Reservado para OCR (no implementado)

## Package Android

`com.webpack123.limpio` (mismo que la app Expo original)
