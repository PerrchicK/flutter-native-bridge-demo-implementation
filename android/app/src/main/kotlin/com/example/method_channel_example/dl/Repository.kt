package com.example.method_channel_example.dl

import android.content.Context
import android.content.SharedPreferences
import androidx.annotation.Nullable
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import com.example.method_channel_example.utils.AppLogger
import java.io.IOException
import java.lang.ref.WeakReference
import java.security.GeneralSecurityException

class Repository(applicationContext: Context) {
    private val applicationContext: WeakReference<Context> = WeakReference(applicationContext)

    companion object {
        private val TAG = Repository::class.java.simpleName
    }

    private val securedSharedPreferences: SharedPreferences? by lazy {
        generateSecuredSharedPreferences()
    }

    fun storeSecuredString(key: String, value: String): Boolean {
        //        val fileEditor = getContext()
//                .getSharedPreferences(fileName, Context.MODE_PRIVATE)
//                .edit()

        //TODO: Of course, this should also reflect the Editor's attitude
        return securedSharedPreferences?.edit()?.putString(key, value)?.commit() ?: false

        //        fileEditor.apply()
    }

    fun loadSecuredString(key: String, defaultValue: String?): String? {
        if (key.isEmpty()) return ""
        return securedSharedPreferences?.getString(key, defaultValue)
    }

    @Nullable
    private fun generateSecuredSharedPreferences(): SharedPreferences? {
        var sharedPreferences: SharedPreferences? = null
        applicationContext.get()?.let { context ->
            try {
                val masterKeyAlias: String = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
                sharedPreferences = EncryptedSharedPreferences.create(
                        "secret_$TAG",
                        masterKeyAlias,
                        context,
                        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                )
            } catch (e: GeneralSecurityException) {
                AppLogger.error(TAG, e)
            } catch (e: IOException) {
                AppLogger.error(TAG, e)
            }
        } ?: run {
            AppLogger.error(TAG, "Failed to get application context")
        }

        return sharedPreferences
    }

}
