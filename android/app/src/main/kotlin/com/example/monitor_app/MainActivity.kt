package com.example.monitor_app

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.monitor_app/media_projection"
    private val EVENT_CHANNEL = "com.example.monitor_app/ride_events"
    private val OVERLAY_PERMISSION_CODE = 101
    private val NOTIFICATION_PERMISSION_CODE = 102
    private val PERMISSION_CODE = 1000
    private var resultCode: Int = 0
    private var resultData: Intent? = null
    private var mediaProjection: MediaProjection? = null
    private var mediaProjectionManager: MediaProjectionManager? = null
    private var methodResult: MethodChannel.Result? = null
    private var imageReader: ImageReader? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var handler: Handler? = null
    private var screenWidth: Int = 0
    private var screenHeight: Int = 0
    private var screenDensity: Int = 0
    private var eventSink: EventChannel.EventSink? = null
    private var notificationReceiver: BroadcastReceiver? = null
    
    companion object {
        private const val TAG = "MainActivity"
        const val ACTION_CAPTURE_SCREEN = "com.example.monitor_app.ACTION_CAPTURE_SCREEN"
    }    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Obter dimensões da tela
        val metrics = DisplayMetrics()
        (getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay.getMetrics(metrics)
        screenWidth = metrics.widthPixels
        screenHeight = metrics.heightPixels
        screenDensity = metrics.densityDpi

        handler = Handler(Looper.getMainLooper())
        
        // Configurar receptor de broadcasts para notificações de corrida
        setupNotificationReceiver()
        
        // Configurar canal de eventos para Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
          MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestMediaProjection" -> {
                    methodResult = result
                    requestMediaProjection()
                }
                "hasMediaProjectionPermission" -> {
                    result.success(mediaProjection != null)
                }                "captureScreen" -> {
                    captureScreen(result)
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "requestNotificationListenerPermission" -> {
                    requestNotificationListenerPermission()
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    result.success(checkOverlayPermission())
                }
                "checkNotificationListenerPermission" -> {
                    result.success(checkNotificationListenerPermission())
                }
                "showOverlay" -> {
                    val price = call.argument<Double>("price") ?: 0.0
                    val pricePerKm = call.argument<Double>("pricePerKm") ?: 0.0
                    val pricePerMinute = call.argument<Double>("pricePerMinute") ?: 0.0
                    val pricePerSegment = call.argument<Double>("pricePerSegment") ?: 0.0
                    
                    showOverlay(price, pricePerKm, pricePerMinute, pricePerSegment)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun setupNotificationReceiver() {
        // Registrar receptor de broadcast para receber notificações de corridas
        notificationReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == RideNotificationListenerService.ACTION_RIDE_NOTIFICATION) {
                    val appName = intent.getStringExtra(RideNotificationListenerService.EXTRA_APP_NAME) ?: return
                    val title = intent.getStringExtra(RideNotificationListenerService.EXTRA_NOTIFICATION_TITLE) ?: ""
                    val text = intent.getStringExtra(RideNotificationListenerService.EXTRA_NOTIFICATION_TEXT) ?: ""
                    
                    // Capturar tela e enviar para o Flutter
                    val eventData = HashMap<String, Any>()
                    eventData["appName"] = appName
                    eventData["title"] = title
                    eventData["text"] = text
                    eventData["eventType"] = "ride_notification"
                    
                    // Enviar evento para Flutter
                    handler?.post {
                        eventSink?.success(eventData)
                    }
                }
            }
        }
        
        val filter = IntentFilter(RideNotificationListenerService.ACTION_RIDE_NOTIFICATION)
        registerReceiver(notificationReceiver, filter)
    }
    
    private fun checkOverlayPermission(): Boolean {
        return Settings.canDrawOverlays(this)
    }
    
    private fun requestOverlayPermission() {
        if (!checkOverlayPermission()) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_CODE)
        }
    }
    
    private fun checkNotificationListenerPermission(): Boolean {
        val packageName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat?.contains(packageName) ?: false
    }
    
    private fun requestNotificationListenerPermission() {
        if (!checkNotificationListenerPermission()) {
            val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
            startActivityForResult(intent, NOTIFICATION_PERMISSION_CODE)
        }
    }
    
    private fun showOverlay(price: Double, pricePerKm: Double, pricePerMinute: Double, pricePerSegment: Double) {
        val intent = Intent(this, OverlayService::class.java).apply {
            action = OverlayService.ACTION_SHOW_OVERLAY
            putExtra(OverlayService.EXTRA_PRICE, price)
            putExtra(OverlayService.EXTRA_PRICE_PER_KM, pricePerKm)
            putExtra(OverlayService.EXTRA_PRICE_PER_MINUTE, pricePerMinute)
            putExtra(OverlayService.EXTRA_PRICE_PER_SEGMENT, pricePerSegment)
        }
        startService(intent)
    }

    private fun requestMediaProjection() {
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(
            mediaProjectionManager!!.createScreenCaptureIntent(),
            PERMISSION_CODE
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == PERMISSION_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                this.resultCode = resultCode
                this.resultData = data
                mediaProjection = mediaProjectionManager?.getMediaProjection(resultCode, data)
                methodResult?.success(true)
            } else {
                methodResult?.success(false)
            }
            methodResult = null
        }
    }

    private fun captureScreen(result: MethodChannel.Result) {
        if (mediaProjection == null) {
            result.error("NO_PERMISSION", "Não há permissão para capturar a tela", null)
            return
        }

        try {
            // Configurar ImageReader para captura
            imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 2)

            // Criar display virtual
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "screen-mirror",
                screenWidth, screenHeight, screenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader?.surface, null, handler
            )

            // Pequeno delay para garantir que a captura esteja pronta
            handler?.postDelayed({
                val image = imageReader?.acquireLatestImage()
                if (image != null) {
                    // Processar a imagem e convertê-la em bytes
                    val planes = image.planes
                    val buffer = planes[0].buffer
                    val pixelStride = planes[0].pixelStride
                    val rowStride = planes[0].rowStride
                    val rowPadding = rowStride - pixelStride * screenWidth

                    // Criar bitmap a partir do buffer
                    val bitmap = Bitmap.createBitmap(
                        screenWidth + rowPadding / pixelStride, screenHeight,
                        Bitmap.Config.ARGB_8888
                    )
                    bitmap.copyPixelsFromBuffer(buffer)

                    // Converter bitmap para PNG bytes
                    val baos = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos)
                    val byteArray = baos.toByteArray()

                    // Limpar recursos
                    bitmap.recycle()
                    image.close()
                    virtualDisplay?.release()
                    virtualDisplay = null

                    // Retornar os bytes da imagem
                    result.success(byteArray)
                } else {
                    result.error("CAPTURE_FAILED", "Falha ao capturar a imagem", null)
                    virtualDisplay?.release()
                    virtualDisplay = null
                }
            }, 100) // pequeno delay para garantir que a captura esteja pronta
        } catch (e: Exception) {
            result.error("CAPTURE_ERROR", "Erro ao capturar tela: ${e.message}", null)
        }
    }

    override fun onDestroy() {
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        super.onDestroy()
    }
}
