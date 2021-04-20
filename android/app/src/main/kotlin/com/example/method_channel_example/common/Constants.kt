package com.example.method_channel_example.common

import com.example.method_channel_example.BuildConfig

// test
class Constants {
    class Keys {
        class Persistence {
            companion object {
                const val TEMP_IMAGE = "tempImage"
                const val LOCATION_WORKER_FILE_NAME = "LocationWorker"
                const val LAST_LOCATION_WORKER_CALL = "LastServiceCall"
            }
        }

        class Extra {
            companion object {
                const val SHOULD_SKIP_SPLASH = "SHOULD_SKIP_SPLASH"
                const val URL_STRING = "URL_STRING"
                const val AnalyticsEvent = "analytics_event"
                const val LOCATION = "location"
                const val isAbleToSelectLocation = "isAbleToSelectLocation"
            }
        }

        class FlutterMethodChannel {
            companion object {
                const val FAILURE_RESULT = "0"
                const val SUCCESS_RESULT = "1"
                const val DATA_KEY = "dataKey"
                const val DATA_VALUE = "dataValue"
            }
        }
    }

    companion object {
        const val APP_ID: String = "com.perrchick.beya"
        const val ONE_MINUTE_MILLISECONDS: Long = 1000 * 60
        const val ONE_HOUR_IN_MILLISECONDS: Long = ONE_MINUTE_MILLISECONDS * 60
    }
}

enum class Environment {
    PRODUCTION, DEVELOPMENT;

    override fun toString(): String {
        return when (this) {
            DEVELOPMENT -> DEVELOPMENT_STRING
            PRODUCTION -> PRODUCTION_STRING
        }
    }

    companion object {
        private const val DEV_FLAVOR_STRING: String = "development"
        private const val DEVELOPMENT_STRING: String = "development"
        private const val PRODUCTION_STRING: String = "production"

        fun currentEnvironment(): Environment {
            @Suppress("ConstantConditionIf", "LiftReturnOrAssignment")
            if (BuildConfig.FLAVOR == DEV_FLAVOR_STRING) {
                return DEVELOPMENT
            } else {
                return PRODUCTION
            }
        }
    }

}