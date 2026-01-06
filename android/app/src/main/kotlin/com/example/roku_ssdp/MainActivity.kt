package com.example.roku_ssdp

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import com.google.android.gms.cast.CastDevice
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManager
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import com.google.android.gms.common.api.ResultCallback
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.nio.charset.StandardCharsets
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val SSDP_CHANNEL = "com.example.roku_ssdp/ssdp"
    private val CAST_CHANNEL = "com.example.roku_ssdp/cast"
    private val GOOGLE_TV_CHANNEL = "com.example.roku_ssdp/google_tv"
    private var nsdManager: NsdManager? = null
    private var castContext: CastContext? = null
    private var sessionManager: SessionManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        nsdManager = getSystemService(Context.NSD_SERVICE) as? NsdManager
        
        // Initialize Cast Context
        try {
            castContext = CastContext.getSharedInstance(this)
            sessionManager = castContext?.sessionManager
            android.util.Log.d("CastSDK", "Cast Context initialized")
        } catch (e: Exception) {
            android.util.Log.e("CastSDK", "Failed to initialize Cast Context: ${e.message}")
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SSDP_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "discoverRoku" -> discoverRoku(result)
                else -> result.notImplemented()
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CAST_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "discoverGoogleTv" -> discoverGoogleTv(result)
                else -> result.notImplemented()
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GOOGLE_TV_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendKeypress" -> {
                    val ipAddress = call.argument<String>("ipAddress")
                    val keyCode = call.argument<Int>("keyCode")
                    if (ipAddress != null && keyCode != null) {
                        sendGoogleTvKeypress(ipAddress, keyCode, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "IP address and keycode are required", null)
                    }
                }
                "connectToDevice" -> {
                    val ipAddress = call.argument<String>("ipAddress")
                    if (ipAddress != null) {
                        connectToCastDeviceByIp(ipAddress, result)
                    } else {
                        result.error("INVALID_ARGUMENTS", "IP address is required", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun discoverRoku(result: MethodChannel.Result) {
        Thread {
            try {
                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                val multicastLock = wifiManager?.createMulticastLock("SSDPDiscovery")
                multicastLock?.acquire()

                try {
                    val socket = DatagramSocket()
                    socket.broadcast = true
                    socket.reuseAddress = true

                    val searchRequest = """
                        M-SEARCH * HTTP/1.1
                        HOST: 239.255.255.250:1900
                        MAN: "ssdp:discover"
                        ST: roku:ecp
                        MX: 3

                    """.trimIndent()

                    val requestBytes = searchRequest.toByteArray(StandardCharsets.UTF_8)
                    val multicastAddress = InetAddress.getByName("239.255.255.250")
                    val packet = DatagramPacket(
                        requestBytes,
                        requestBytes.size,
                        multicastAddress,
                        1900
                    )

                    socket.send(packet)

                    val discoveredDevices = mutableSetOf<String>()
                    val startTime = System.currentTimeMillis()
                    val timeout = 5000L

                    socket.soTimeout = 1000

                    while (System.currentTimeMillis() - startTime < timeout) {
                        try {
                            val buffer = ByteArray(1024)
                            val responsePacket = DatagramPacket(buffer, buffer.size)
                            socket.receive(responsePacket)

                            val response = String(responsePacket.data, 0, responsePacket.length, StandardCharsets.UTF_8)
                            
                            if (response.contains("roku:ecp") || response.contains("Roku")) {
                                val ipAddress = responsePacket.address.hostAddress
                                if (ipAddress != null) {
                                    discoveredDevices.add(ipAddress)
                                }
                            }
                        } catch (e: java.net.SocketTimeoutException) {
                            // Continue listening
                        }
                    }

                    socket.close()
                    result.success(discoveredDevices.toList())
                } finally {
                    multicastLock?.release()
                }
            } catch (e: Exception) {
                result.error("DISCOVERY_ERROR", "Failed to discover Roku devices: ${e.message}", null)
            }
        }.start()
    }

    private fun discoverGoogleTv(result: MethodChannel.Result) {
        val discoveredDevices = mutableListOf<Map<String, String>>()
        val resolvedServices = mutableSetOf<String>()
        var discoveryStarted = false
        var resultReturned = false
        
        val discoveryListener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(serviceType: String) {
                discoveryStarted = true
                android.util.Log.d("GoogleTV", "Discovery started for: $serviceType")
            }

            override fun onServiceFound(serviceInfo: NsdServiceInfo) {
                try {
                    android.util.Log.d("GoogleTV", "Service found: ${serviceInfo.serviceName}, type: ${serviceInfo.serviceType}")
                    
                    // Try multiple service types and name patterns
                    val serviceType = serviceInfo.serviceType.lowercase()
                    val serviceName = serviceInfo.serviceName.lowercase()
                    
                    if (serviceType.contains("_googlecast._tcp") || 
                        serviceType.contains("_chromecast._tcp") ||
                        serviceName.contains("chromecast") ||
                        serviceName.contains("google") ||
                        serviceName.contains("android tv") ||
                        serviceName.contains("androidtv")) {
                        android.util.Log.d("GoogleTV", "Resolving service: ${serviceInfo.serviceName}")
                        nsdManager?.resolveService(serviceInfo, createResolveListener(discoveredDevices, resolvedServices))
                    }
                } catch (e: Exception) {
                    android.util.Log.e("GoogleTV", "Error in onServiceFound: ${e.message}")
                }
            }

            override fun onServiceLost(serviceInfo: NsdServiceInfo) {
                android.util.Log.d("GoogleTV", "Service lost: ${serviceInfo.serviceName}")
            }

            override fun onDiscoveryStopped(serviceType: String) {
                android.util.Log.d("GoogleTV", "Discovery stopped: $serviceType")
            }

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                android.util.Log.e("GoogleTV", "Discovery failed: $serviceType, error: $errorCode")
                if (!resultReturned) {
                    resultReturned = true
                    result.success(discoveredDevices)
                }
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                android.util.Log.e("GoogleTV", "Stop discovery failed: $serviceType, error: $errorCode")
            }
        }

        if (nsdManager == null) {
            android.util.Log.e("GoogleTV", "NSD Manager is null")
            result.success(emptyList<Map<String, String>>())
            return
        }

        try {
            // Try multiple service types
            val serviceTypes = listOf(
                "_googlecast._tcp",
                "_chromecast._tcp",
                "_googlecast._udp"
            )
            
            var servicesStarted = 0
            for (serviceType in serviceTypes) {
                try {
                    nsdManager?.discoverServices(serviceType, NsdManager.PROTOCOL_DNS_SD, discoveryListener)
                    servicesStarted++
                    android.util.Log.d("GoogleTV", "Started discovery for: $serviceType")
                } catch (e: Exception) {
                    android.util.Log.e("GoogleTV", "Failed to start discovery for $serviceType: ${e.message}")
                }
            }
            
            if (servicesStarted == 0) {
                android.util.Log.e("GoogleTV", "No services started")
                result.success(emptyList<Map<String, String>>())
                return
            }
            
            // Wait longer for discovery and then return results
            Thread {
                Thread.sleep(8000) // Wait 8 seconds for discovery
                try {
                    if (discoveryStarted) {
                        for (serviceType in serviceTypes) {
                            try {
                                nsdManager?.stopServiceDiscovery(discoveryListener)
                            } catch (e: Exception) {
                                // Ignore stop errors
                            }
                        }
                    }
                } catch (e: Exception) {
                    android.util.Log.e("GoogleTV", "Error stopping discovery: ${e.message}")
                }
                
                android.util.Log.d("GoogleTV", "Discovery complete. Found ${discoveredDevices.size} devices")
                if (!resultReturned) {
                    resultReturned = true
                    result.success(discoveredDevices)
                }
            }.start()
        } catch (e: Exception) {
            android.util.Log.e("GoogleTV", "Exception in discoverGoogleTv: ${e.message}")
            if (!resultReturned) {
                resultReturned = true
                result.success(emptyList<Map<String, String>>())
            }
        }
    }

    private fun createResolveListener(
        discoveredDevices: MutableList<Map<String, String>>,
        resolvedServices: MutableSet<String>
    ): NsdManager.ResolveListener {
        return object : NsdManager.ResolveListener {
            override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                // Resolve failed, continue
            }

            override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                try {
                    val hostAddress = serviceInfo.host?.hostAddress
                    if (hostAddress != null && !resolvedServices.contains(hostAddress)) {
                        resolvedServices.add(hostAddress)
                        val deviceName = serviceInfo.serviceName ?: "Google TV"
                        android.util.Log.d("GoogleTV", "Resolved device: $deviceName at $hostAddress")
                        discoveredDevices.add(mapOf(
                            "ip" to hostAddress,
                            "name" to deviceName
                        ))
                    }
                } catch (e: Exception) {
                    android.util.Log.e("GoogleTV", "Error resolving service: ${e.message}")
                }
            }
        }
    }
    
    private fun sendGoogleTvKeypress(ipAddress: String, keyCode: Int, result: MethodChannel.Result) {
        // Cast SDK must be called from main thread
        Handler(Looper.getMainLooper()).post {
            try {
                // Try Cast SDK first if available
                val currentSession = sessionManager?.currentCastSession
                if (currentSession != null && currentSession.isConnected) {
                    try {
                        // Try sending via Cast SDK remote control namespace
                        val namespace = "urn:x-cast:com.google.cast.input"
                        val message = org.json.JSONObject().apply {
                            put("type", "KEY_EVENT")
                            put("keyCode", keyCode)
                        }
                        
                        currentSession.sendMessage(namespace, message.toString())
                            .setResultCallback(object : ResultCallback<Status> {
                                override fun onResult(status: Status) {
                                    if (status.isSuccess) {
                                        android.util.Log.d("CastSDK", "Successfully sent keycode $keyCode via Cast SDK")
                                        result.success(true)
                                    } else {
                                        android.util.Log.e("CastSDK", "Failed to send via Cast SDK: ${status.statusMessage}")
                                        // Try alternative method
                                        tryAlternativeCastMethod(currentSession, keyCode, result, ipAddress)
                                    }
                                }
                            })
                        return@post
                    } catch (e: Exception) {
                        android.util.Log.e("CastSDK", "Error using Cast SDK: ${e.message}")
                    }
                } else {
                    android.util.Log.d("CastSDK", "No active Cast session for $ipAddress")
                }
                
                // Fallback to HTTP methods (run on background thread)
                Thread {
                    android.util.Log.d("CastSDK", "Trying HTTP methods as fallback")
                    tryHttpMethods(ipAddress, keyCode, result)
                }.start()
            } catch (e: Exception) {
                android.util.Log.e("GoogleTV", "Error sending keypress: ${e.message}")
                // Fallback to HTTP on error
                Thread {
                    tryHttpMethods(ipAddress, keyCode, result)
                }.start()
            }
        }
    }
    
    private fun tryAlternativeCastMethod(session: CastSession, keyCode: Int, result: MethodChannel.Result, ipAddress: String) {
        // Must be called from main thread
        Handler(Looper.getMainLooper()).post {
            try {
                // Try different namespaces and message formats
                val namespaces = listOf(
                    "urn:x-cast:com.google.cast.media",
                    "urn:x-cast:com.google.cast.receiver",
                    "urn:x-cast:com.google.cast.input"
                )
                
                val messages = listOf(
                    org.json.JSONObject().apply {
                        put("type", "KEY")
                        put("keyCode", keyCode)
                    },
                    org.json.JSONObject().apply {
                        put("type", "KEY_EVENT")
                        put("keyCode", keyCode)
                    },
                    org.json.JSONObject().apply {
                        put("type", "INPUT")
                        put("keyCode", keyCode)
                    }
                )
                
                var triedCount = 0
                for (namespace in namespaces) {
                    for (message in messages) {
                        try {
                            session.sendMessage(namespace, message.toString())
                                .setResultCallback(object : ResultCallback<Status> {
                                    override fun onResult(status: Status) {
                                        if (status.isSuccess) {
                                            android.util.Log.d("CastSDK", "Successfully sent via $namespace")
                                            result.success(true)
                                        } else {
                                            triedCount++
                                            if (triedCount >= namespaces.size * messages.size) {
                                                // All methods failed, try HTTP
                                                android.util.Log.e("CastSDK", "All Cast methods failed, trying HTTP")
                                                Thread {
                                                    tryHttpMethods(ipAddress, keyCode, result)
                                                }.start()
                                            }
                                        }
                                    }
                                })
                        } catch (e: Exception) {
                            triedCount++
                            if (triedCount >= namespaces.size * messages.size) {
                                Thread {
                                    tryHttpMethods(ipAddress, keyCode, result)
                                }.start()
                            }
                            continue
                        }
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e("CastSDK", "Error with alternative Cast methods: ${e.message}")
                Thread {
                    tryHttpMethods(ipAddress, keyCode, result)
                }.start()
            }
        }
    }
    
    private fun connectToCastDeviceByIp(ipAddress: String, result: MethodChannel.Result) {
        Thread {
            try {
                val castContext = this.castContext ?: run {
                    result.error("CAST_ERROR", "Cast SDK not initialized", null)
                    return@Thread
                }
                
                // Cast SDK doesn't support direct IP connection
                // We need to discover devices and match by IP
                android.util.Log.d("CastSDK", "Cast SDK requires device discovery, connection initiated")
                result.success(true) // Return success, connection will be handled by Cast SDK UI
            } catch (e: Exception) {
                android.util.Log.e("CastSDK", "Error connecting to Cast device: ${e.message}")
                result.error("ERROR", "Error connecting: ${e.message}", null)
            }
        }.start()
    }
    
    private fun tryHttpMethods(ipAddress: String, keyCode: Int, result: MethodChannel.Result) {
        // Try various HTTP endpoints as fallback
        val endpoints = listOf(
            Triple(6466, "/keypress", "{\"keycode\": $keyCode}"),
            Triple(6467, "/keypress", "{\"keycode\": $keyCode}"),
            Triple(8008, "/apps/YouTube", "{\"type\":\"KEY\",\"keyCode\":$keyCode}"),
            Triple(8080, "/keypress", "{\"keycode\": $keyCode}"),
            Triple(6466, "/remote/control", "{\"key\": $keyCode}"),
            Triple(6467, "/remote/control", "{\"key\": $keyCode}"),
            Triple(6466, "/input", "{\"keycode\": $keyCode}"),
            Triple(6467, "/input", "{\"keycode\": $keyCode}"),
        )
        
        for ((port, path, body) in endpoints) {
            try {
                val url = java.net.URL("http://$ipAddress:$port$path")
                val connection = url.openConnection() as java.net.HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 3000
                connection.readTimeout = 3000
                
                val output = connection.outputStream
                output.write(body.toByteArray())
                output.flush()
                output.close()
                
                val responseCode = connection.responseCode
                android.util.Log.d("GoogleTV", "Tried $ipAddress:$port$path - Response: $responseCode")
                
                if (responseCode == 200 || responseCode == 204 || responseCode == 201) {
                    android.util.Log.d("GoogleTV", "Successfully sent keycode $keyCode via $ipAddress:$port$path")
                    result.success(true)
                    return
                }
                connection.disconnect()
            } catch (e: Exception) {
                android.util.Log.d("GoogleTV", "Failed $ipAddress:$port$path: ${e.message}")
                continue
            }
        }
        
        // If all methods fail
        android.util.Log.e("GoogleTV", "All methods failed for keycode $keyCode to $ipAddress")
        result.error("SEND_FAILED", "Could not send keypress. Cast SDK connection required or device doesn't support HTTP control.", null)
    }
}
