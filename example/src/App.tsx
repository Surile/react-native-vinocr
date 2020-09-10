import * as React from 'react';
import { StyleSheet, View, Text, Button, Image, Platform } from 'react-native';
import Vinocr from 'react-native-vinocr';
import ImagePicker, { ImagePickerOptions } from 'react-native-image-picker';

export default function App() {
  const [result, setResult] = React.useState<number | undefined>();
  const [imgUrl, setImgUrl] = React.useState<string | undefined>();

  /**
   * 视频流识别
   * recogResult 识别结果
   * urlResult 识别图片地址
   */
  const cameraVIN = () => {
    if (Platform.OS === 'android') {
      Vinocr.cameraRequest((recogResult: number, urlResult: string) => {
        setResult(recogResult);
        setImgUrl(urlResult);
      });
    } else {
      Vinocr.vinRecognizeFinish('9C15EEA95B60787AEEEA')
        .then((result: any) => {
          setResult(result.vinStr);
          setImgUrl(result.areaVinImagePath);
        })
        .catch((err) => {
          console.log('err', err);
        });
    }
  };

  /**
   * 导入识别
   */
  const importVIN = () => {
    selectPhotoTapped();
  };

  /**
   * 调用识别核心
   * picPath 传入的图片地址
   * recogResult 识别结果
   * urlResult 识别图片地址
   */
  const decernVin = (source: string) => {
    // 调用识别核心
    Vinocr.RecogImg(source, (recogResult: number, urlResult: string) => {
      setResult(recogResult);
      setImgUrl(urlResult);
    });
  };

  //选择图片
  const selectPhotoTapped = () => {
    const options: ImagePickerOptions = {
      title: '选择图片',
      cancelButtonTitle: '取消',
      takePhotoButtonTitle: '拍照',
      chooseFromLibraryButtonTitle: '选择照片',
      cameraType: 'back',
      mediaType: 'photo',
      videoQuality: 'high',
      allowsEditing: false,
      noData: false,
      storageOptions: {
        skipBackup: true,
      },
    };
    ImagePicker.showImagePicker(options, (response) => {
      console.log('Response = ', response);
      if (response.didCancel) {
        console.log('User cancelled photo picker');
      } else if (response.error) {
        console.log('ImagePicker Error: ', response.error);
      } else if (response.customButton) {
        console.log('User tapped custom button: ', response.customButton);
      } else {
        // let source = { uri: response.uri } ;
        let source: string = response.path || '';
        // You can also display the image using data:
        // let source = { uri: 'data:image/jpeg;base64,' + response.data };
        // setAvatarSource(source);
        decernVin(source); // 识别
      }
    });
  };

  const iosImport = () => {
    Vinocr.multiply(2, 3)
      .then((res: number) => {
        console.log('res', res);
      })
      .catch((err) => {
        console.warn(err);
      });
  };

  return (
    <View style={styles.allStyle}>
      <Text style={styles.tipText}>识别结果:</Text>
      <View style={styles.container}>
        <Text style={styles.bigBlue}>{result}</Text>
        <Text style={styles.smallBlue}>{imgUrl}</Text>
        {imgUrl ? (
          <Image source={{ uri: 'file://' + imgUrl }} style={styles.imgUrl} />
        ) : null}
      </View>
      <View style={styles.container2}>
        <Button onPress={cameraVIN} title="扫描识别" color="#524cd5" />
        <Button onPress={importVIN} title="导入识别" color="#524cd5" />
        <Button onPress={iosImport} title="ios原生与RN交互" color="#524cd5" />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  allStyle: {
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 120,
  },
  container2: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: 20,
  },
  container: {
    justifyContent: 'center',
  },
  bigBlue: {
    color: '#524cd5',
    fontWeight: 'bold',
    fontSize: 30,
  },
  smallBlue: {
    color: '#524cd5',
    fontSize: 10,
  },
  tipText: {
    color: '#000000',
    fontSize: 12,
  },
  imgUrl: {
    width: 300,
    height: 60,
  },
});
