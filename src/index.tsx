import { NativeModules } from 'react-native';

type VinocrType = {
  multiply(a: number, b: number): Promise<number>;
};

const { Vinocr } = NativeModules;

export default Vinocr as VinocrType;
