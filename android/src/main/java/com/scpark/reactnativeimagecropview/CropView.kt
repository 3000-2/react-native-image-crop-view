package com.scpark.reactnativeimagecropview

import android.graphics.Bitmap
import android.net.Uri
import com.canhub.cropper.CropImageView
import com.facebook.react.bridge.*
import com.facebook.react.common.MapBuilder
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.UIManagerModule
import com.facebook.react.uimanager.annotations.ReactProp
import java.io.File
import java.util.*

/**
 * CropView 네이티브 모듈과 뷰 매니저를 관리하는 클래스
 * 코드 관리를 위해 모듈과 매니저를 하나의 파일에 통합했습니다.
 */

/**
 * CropView React Native 모듈
 * JavaScript에서 호출할 수 있는 메서드를 제공합니다.
 */
class CropViewModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {
    
    override fun getName(): String {
        return "CropView" // 모듈 이름을 CropView로 변경
    }

    @ReactMethod
    fun cropImage(reactTag: Int, preserveTransparency: Boolean, quality: Int, promise: Promise) {
        val uiManager = reactContext.getNativeModule(UIManagerModule::class.java)
        uiManager?.addUIBlock { nativeViewHierarchyManager ->
            val cropView = nativeViewHierarchyManager.resolveView(reactTag) as? CropImageView

            if (cropView == null) {
                promise.reject("crop_error", "CropView not found")
                return@addUIBlock
            }

            if (cropView.croppedImage == null) {
                promise.reject("crop_error", "Image not loaded")
                return@addUIBlock
            }

            try {
                var extension = "jpg"
                var format = Bitmap.CompressFormat.JPEG

                if (preserveTransparency && cropView.croppedImage!!.hasAlpha()) {
                    extension = "png"
                    format = Bitmap.CompressFormat.PNG
                }

                val path = File(cropView.context.cacheDir, "${UUID.randomUUID()}.$extension").toURI().toString()
                val uri = Uri.parse(path)

                cropView.setOnCropImageCompleteListener { view, result ->
                    if (result.isSuccessful) {
                        val map = Arguments.createMap().apply {
                            putString("uri", uri.toString())
                            putInt("x", result.cropRect?.left ?: 0)
                            putInt("y", result.cropRect?.top ?: 0)
                            putInt("width", result.cropRect?.width() ?: 0)
                            putInt("height", result.cropRect?.height() ?: 0)
                        }
                        promise.resolve(map)
                    } else {
                        promise.reject("crop_error", "Failed to crop image")
                    }
                }

                cropView.croppedImageAsync(format, quality, customOutputUri = uri)
            } catch (e: Exception) {
                promise.reject("crop_error", "Failed to crop image", e)
            }
        }
    }

    @ReactMethod
    fun rotateImage(reactTag: Int, clockwise: Boolean, promise: Promise) {
        val uiManager = reactContext.getNativeModule(UIManagerModule::class.java)
        uiManager?.addUIBlock { nativeViewHierarchyManager ->
            val cropView = nativeViewHierarchyManager.resolveView(reactTag) as? CropImageView

            if (cropView == null) {
                promise.reject("rotate_error", "CropView not found")
                return@addUIBlock
            }

            try {
                cropView.rotateImage(if (clockwise) 90 else -90)
                promise.resolve(null)
            } catch (e: Exception) {
                promise.reject("rotate_error", "Failed to rotate image", e)
            }
        }
    }
}

/**
 * CropView React Native 뷰 매니저
 * React Native에서 사용할 수 있는 네이티브 뷰를 관리합니다.
 */
class CropViewManager : SimpleViewManager<CropImageView>() {
    companion object {
        const val REACT_CLASS = "CropView"
        const val ON_CROP_MOVE = "onCropMove"
        const val SOURCE_URL_PROP = "sourceUrl"
        const val KEEP_ASPECT_RATIO_PROP = "keepAspectRatio"
        const val ASPECT_RATIO_PROP = "cropAspectRatio"
    }

    override fun createViewInstance(reactContext: ThemedReactContext): CropImageView {
        val view = CropImageView(reactContext)
        return view
    }

    override fun getName(): String {
        return REACT_CLASS
    }

    override fun getExportedCustomDirectEventTypeConstants(): MutableMap<String, Any> {
        return MapBuilder.of(
            ON_CROP_MOVE,
            MapBuilder.of("registrationName", ON_CROP_MOVE)
        )
    }

    @ReactProp(name = SOURCE_URL_PROP)
    fun setSourceUrl(view: CropImageView, url: String?) {
        url?.let {
            view.setImageUriAsync(Uri.parse(it))
        }
    }

    @ReactProp(name = KEEP_ASPECT_RATIO_PROP)
    fun setFixedAspectRatio(view: CropImageView, fixed: Boolean) {
        view.setFixedAspectRatio(fixed)
    }

    @ReactProp(name = ASPECT_RATIO_PROP)
    fun setAspectRatio(view: CropImageView, aspectRatio: ReadableMap?) {
        if (aspectRatio != null) {
            view.setAspectRatio(aspectRatio.getInt("width"), aspectRatio.getInt("height"))
        } else {
            view.clearAspectRatio()
        }
    }
}

/**
 * CropView React Native 패키지
 * 모듈과 뷰 매니저를 등록합니다.
 */
class CropViewPackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext): List<NativeModule> {
        return mutableListOf(CropViewModule(reactContext))
    }

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> {
        return mutableListOf(CropViewManager())
    }
}