# Modelo de OCR para escaneo de facturas

## Qué modelo usamos

**Google ML Kit Text Recognition** (script latino), vía el paquete Flutter [`google_mlkit_text_recognition`](https://pub.dev/packages/google_mlkit_text_recognition).

- Corre **on-device** (en el teléfono).
- No requiere API key ni cuenta de Google Cloud.
- No envía la imagen de la factura a un servidor externo.
- Es **gratuito** para este uso.

En código: `TextRecognizer(script: TextRecognitionScript.latin)` en `lib/services/invoice_scanner_service.dart`.

## ¿El modelo corre en el teléfono? ¿Cómo llega?

Sí. El OCR se ejecuta **en el dispositivo**. La foto no se sube a un servidor para “leerse”; el cálculo ocurre en la CPU/GPU del teléfono.

### Cómo llega al teléfono

ML Kit ofrece dos vías de entrega. Limpio usa la **empaquetada (bundled)**:

1. El plugin Flutter depende de `com.google.mlkit:text-recognition` (librería nativa de Google).
2. Al hacer `flutter build apk`, Gradle descarga esa librería desde Maven y la **enlaza en el APK**.
3. Al instalar Limpio (`adb install` o Play Store), el modelo de OCR latino **viaja con la app**.
4. En el primer escaneo no hace falta descargar un modelo aparte por red (a diferencia de la variante *unbundled* vía Play Services).

Por eso el APK es más pesado: no solo lleva el código Dart, también el motor nativo de OCR.

| Pregunta | Respuesta |
|----------|-----------|
| ¿Corre en el teléfono? | Sí |
| ¿La factura sale a internet por el OCR? | No |
| ¿Cómo llega el modelo? | Empaquetado en el APK al instalar Limpio |
| ¿Quién lo entrenó? | Google (nosotros no lo entrenamos; solo lo usamos) |

### Qué pasa en un escaneo

```
Dart (InvoiceScannerService)
  → platform channel
    → código nativo Android (plugin ML Kit)
      → modelo on-device en el teléfono
        → texto + bounding boxes
  ← vuelve a Dart
    → parsers Dart interpretan el TOTAL
```

Dart **no** ejecuta la red neuronal. Solo pide “procesa esta imagen” y recibe el resultado. El ML corre en código nativo de Google dentro del proceso de la app.

Instalar Limpio = instalar también ese motor de lectura de texto. Luego cada escaneo usa ese motor local; los parsers Dart deciden qué número es el monto.

## Por qué este modelo

| Criterio | Decisión |
|----------|----------|
| Costo | Sin facturación ni cuotas cloud |
| Privacidad | La foto no sale del dispositivo |
| Offline | Funciona sin red tras instalar la app (modelo bundled) |
| Android | Encaja con el foco actual de Limpio (sin iOS aún) |
| Datos de layout | Devuelve bloques, líneas, elementos y **bounding boxes** |

Elegimos ML Kit frente a APIs cloud (Document AI, Textract, Gemini, etc.) porque esas opciones suelen pedir clave, red y/o pago. El plan del producto exige modelos **siempre gratuitos** y preferiblemente offline.

## Qué no es este modelo

ML Kit **no** es un extractor de campos de factura entrenado (tipo “campo `total_amount`”). Solo hace **reconocimiento de texto**.

La interpretación del monto (TOTAL, Bs, `$`, fecha, etc.) la hacemos nosotros en Dart:

1. Preproceso de imagen (`invoice_image_preprocessor.dart`)
2. OCR completo + OCR del tercio inferior
3. Parser geométrico con coordenadas (`invoice_layout_parser.dart`)
4. Fallback por texto plano (`invoice_text_parser.dart`)

## Flujo resumido

```
Foto → recorte manual → preproceso → ML Kit (full + bottom)
  → layout (bounding boxes) → fallback texto → revisión → formulario
```

## Alternativas descartadas (por ahora)

- **Gemini / LLMs cloud**: requieren clave, red y cupos; no son “siempre gratis”.
- **Document AI / Textract / Azure Receipts**: APIs de pago o trial limitado.
- **Solo regex sobre texto plano**: barato, pero falla mucho en facturas con columnas (TOTAL a la izquierda, monto a la derecha).

Si en el futuro se aceptara una API con clave y cuota gratis, podría usarse como refuerzo cuando el OCR local no encuentre monto; hoy no forma parte del stack.
