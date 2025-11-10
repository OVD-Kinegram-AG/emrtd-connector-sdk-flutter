package com.kurzdigital.emrtd

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.kinegram.android.emrtdconnector.EmrtdConnectorActivity

class EmrtdPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    // This local reference serves to register the plugin with the Flutter
    // Engine and unregister it when the Flutter Engine is detached from the
    // Activity.
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(
        flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "emrtd")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, resultCode, data ->
            if (requestCode == REQUEST_CODE) {
                pendingResult?.let {
                    if (resultCode == Activity.RESULT_OK) {
                        it.success(data?.getStringExtra("result"))
                    } else {
                        it.error("CANCELLED", "User cancelled", null)
                    }
                    pendingResult = null
                }
                true
            } else false
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(
        binding: ActivityPluginBinding
    ) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "read" -> onRead(call, result)
            else -> result.notImplemented()
        }
    }

    private fun onRead(call: MethodCall, result: Result) {
        if (activity == null) {
            result.error(
                "NO_ACTIVITY",
                "Plugin not attached to an activity",
                null
            )
            return
        }

        // Safely extract arguments from Dart call
        val args = call.arguments as? Map<*, *> ?: run {
            result.error(
                "ARGUMENT_ERROR",
                "Arguments missing or invalid",
                null
            )
            return
        }

        val clientId = args["clientId"] as? String
        val validationUri = args["validationUri"] as? String
        val validationId = args["validationId"] as? String
        val documentNumber = args["documentNumber"] as? String
        val dateOfBirth = args["dateOfBirth"] as? String
        val dateOfExpiry = args["dateOfExpiry"] as? String

        if (clientId == null ||
            validationUri == null ||
            validationId == null ||
            documentNumber == null ||
            dateOfBirth == null ||
            dateOfExpiry == null
        ) {
            result.error(
                "ARGUMENT_MISSING",
                "One or more required arguments are missing",
                null
            )
            return
        }

        pendingResult = result
        activity?.startActivityForResult(
            Intent(activity, EmrtdConnectorActivity::class.java).apply {
                putExtra(EmrtdConnectorActivity.CLIENT_ID, clientId)
                putExtra(EmrtdConnectorActivity.VALIDATION_URI, validationUri)
                putExtra(EmrtdConnectorActivity.VALIDATION_ID_KEY, validationId)
                putExtra(EmrtdConnectorActivity.DOCUMENT_NUMBER_KEY, documentNumber)
                putExtra(EmrtdConnectorActivity.DATE_OF_BIRTH_KEY, dateOfBirth)
                putExtra(EmrtdConnectorActivity.DATE_OF_EXPIRY_KEY, dateOfExpiry)
            },
            REQUEST_CODE
        )
    }

    companion object {
        const val REQUEST_CODE = 1
    }
}
