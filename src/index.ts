import React, { forwardRef, useRef, useImperativeHandle } from 'react';
import {
  requireNativeComponent,
  type ViewStyle,
  NativeModules,
  type ViewProps,
  findNodeHandle,
  Platform,
} from 'react-native';

interface CropViewProps extends ViewProps {
  /**
   * 소스 이미지 URL
   * 로컬 파일 경로, 원격 URL, 또는 iOS의 경우 "ph://" 형식의 Photo Library 참조일 수 있습니다.
   */
  sourceUrl: string;

  /**
   * 종횡비를 유지할지 여부
   * true이면 이미지의 종횡비가 잠깁니다.
   */
  keepAspectRatio?: boolean;

  /**
   * 크롭 영역의 종횡비
   * 예: { width: 16, height: 9 }
   */
  cropAspectRatio?: { width: number; height: number };

  /**
   * iOS에서 치수 스왑 활성화 여부
   * true이면 가로/세로 전환이 가능합니다.
   */
  iosDimensionSwapEnabled?: boolean;

  /**
   * 크롭 영역이 변경될 때 호출되는 콜백
   */
  onCropMove?: (cropInfo: CropInfo) => void;

  /**
   * 컴포넌트 스타일
   */
  style?: ViewStyle;
}

// 크롭 정보 인터페이스
export interface CropInfo {
  width: number;
  height: number;
  x: number;
  y: number;
}

// 크롭 결과 인터페이스
export interface CropResult extends CropInfo {
  uri: string;
}

// CropView 메서드 인터페이스
export interface CropViewHandle {
  /**
   * 이미지를 크롭합니다.
   * @param preserveTransparency 투명도를 유지할지 여부 (기본값: false)
   * @param quality JPEG 품질 (0-100, 기본값: 90)
   * @returns 크롭된 이미지 결과를 담은 Promise
   */
  cropImage: (
    preserveTransparency?: boolean,
    quality?: number
  ) => Promise<CropResult>;

  /**
   * 이미지를 회전합니다.
   * @param clockwise 시계 방향으로 회전할지 여부 (기본값: true)
   */
  rotateImage: (clockwise?: boolean) => void;
}

// 네이티브 컴포넌트 참조
const RCTCropView = requireNativeComponent<CropViewProps>('CropView');

// 네이티브 모듈 이름 (이제 양쪽 모두 'CropView'로 통일)
const CropViewNativeModule = Platform.select({
  ios: NativeModules.CropView,
  android: NativeModules.CropView,
});

// 모듈이 존재하지 않는 경우 오류 처리
if (!CropViewNativeModule) {
  console.error(
    'Native module CropView not found. Make sure react-native-image-crop-view is properly installed.'
  );
}

/**
 * CropView 컴포넌트
 */
const CropView = forwardRef<CropViewHandle, CropViewProps>((props, ref) => {
  const { cropAspectRatio, ...rest } = props;
  const innerRef = useRef<React.ElementRef<typeof RCTCropView>>(null);

  useImperativeHandle(ref, () => ({
    cropImage: (
      preserveTransparency = false,
      quality = 90
    ): Promise<CropResult> => {
      const handle = findNodeHandle(innerRef.current);
      if (!handle) return Promise.reject(new Error('CropView not found'));

      return CropViewNativeModule.cropImage(
        handle,
        preserveTransparency,
        quality
      );
    },

    rotateImage: (clockwise = true): void => {
      const handle = findNodeHandle(innerRef.current);
      if (!handle) return;

      CropViewNativeModule.rotateImage(handle, clockwise);
    },
  }));

  const nativeProps = {
    ...rest,
    cropAspectRatio: cropAspectRatio
      ? { width: cropAspectRatio.width, height: cropAspectRatio.height }
      : undefined,
  };

  return React.createElement(
    RCTCropView,
    Object.assign({}, nativeProps, { ref: innerRef })
  );
});

CropView.displayName = 'CropView';

export default CropView;
