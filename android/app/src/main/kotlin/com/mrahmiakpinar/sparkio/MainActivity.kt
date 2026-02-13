package com.mrahmiakpinar.sparkio

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateHomeWidget" -> {
                        handleUpdateHomeWidget(call)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleUpdateHomeWidget(call: MethodCall) {
        val remainingTasks = (call.argument<Number>("remainingTasks") ?: 0).toInt()
        val timerActive = call.argument<Boolean>("timerActive") ?: false
        val timerFinished = call.argument<Boolean>("timerFinished") ?: false
        val timerTaskTitle = call.argument<String>("timerTaskTitle") ?: ""
        val timerRemainingSec = (call.argument<Number>("timerRemainingSec") ?: 0).toInt()

        SparkioHomeWidgetProvider.saveSnapshot(
            context = this,
            remainingTasks = remainingTasks,
            timerActive = timerActive,
            timerFinished = timerFinished,
            timerTaskTitle = timerTaskTitle,
            timerRemainingSec = timerRemainingSec
        )
        SparkioHomeWidgetProvider.updateAllWidgets(this)
    }

    companion object {
        private const val CHANNEL_NAME = "sparkio/home_widget"
    }
}
