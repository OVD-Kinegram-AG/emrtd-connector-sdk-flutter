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
import com.kinegram.android.emrtdconnector.EmrtdPassport

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
                        val passportData = data?.getParcelableExtra<EmrtdPassport>(
                            EmrtdConnectorActivity.RETURN_DATA
                        )
                        if (passportData == null) {
                            val error = data?.getStringExtra(
                                EmrtdConnectorActivity.RETURN_ERROR
                            )
                            it.error(
                                "CANCELLED",
                                error ?: "Unknown error",
                                null
                            )
                        } else {
                            it.success(passportData.toJSON().toString())
                        }
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
            "readAndVerify" -> onReadAndVerify(
                call,
                result,
                mapOf(
                    EmrtdConnectorActivity.DOCUMENT_NUMBER to "documentNumber",
                    EmrtdConnectorActivity.DATE_OF_BIRTH to "dateOfBirth",
                    EmrtdConnectorActivity.DATE_OF_EXPIRY to "dateOfExpiry",
                )
            )

            "readAndVerifyWithCan",
            "readAndVerifyWithPace",
            "readAndVerifyWithPacePolling" -> onReadAndVerify(
                call,
                result,
                mapOf(EmrtdConnectorActivity.CAN to "can")
            )

            else -> result.notImplemented()
        }
    }

    private fun onReadAndVerify(
        call: MethodCall,
        result: Result,
        arguments: Map<String, String>,
    ) {
        if (activity == null) {
            result.error(
                "NO_ACTIVITY",
                "Plugin not attached to an activity",
                null
            )
            return
        }

        val allArgs = arguments + mapOf(
            EmrtdConnectorActivity.CLIENT_ID to "clientId",
            EmrtdConnectorActivity.VALIDATION_URI to "validationUri",
            EmrtdConnectorActivity.VALIDATION_ID to "validationId",
        )

        pendingResult = result
        activity?.startActivityForResult(
            Intent(activity, EmrtdConnectorActivity::class.java).apply {
                allArgs.forEach { (key, name) ->
                    if (!call.hasArgument(name)) {
                        result.error(
                            "ARGUMENT_MISSING",
                            "$name missing",
                            null
                        )
                        return
                    }
                    putExtra(key, call.argument(name) as? String)
                }
            },
            REQUEST_CODE
        )
    }

    companion object {
        const val REQUEST_CODE = 1
    }
}
