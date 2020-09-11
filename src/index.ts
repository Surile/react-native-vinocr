import { NativeModules } from 'react-native';

type VinocrType = {
  multiply(a: number, b: number): Promise<number>;
  cameraRequest(x: (vinResult: number, vinImgUrl: string) => void): void;
  RecogImg(
    path: string,
    x: (vinResult: number, vinImgUrl: string) => void
  ): void;
  vinRecognizeFinish(a: string): Promise<object>;
  recogVinImage(a: string): Promise<object>;
};

const { Vinocr } = NativeModules;

export default Vinocr as VinocrType;
