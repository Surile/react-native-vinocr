package com.etop.utils;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.text.format.Time;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Random;

/**
 * 写入拍照图像
 */
public class StreamUtil {


    public String saveBitmapFile2(Bitmap bitmap, String filePath, String tag) {
        BufferedOutputStream bos = null;
        File file = new File(filePath, pictureName(tag));
        try {
            file.createNewFile();
            bos = new BufferedOutputStream(new FileOutputStream(file));
            Matrix matrix = new Matrix();
            matrix.setRotate(90);
            bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
            bitmap.compress(Bitmap.CompressFormat.JPEG, 80, bos);
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            try {
                bos.flush();
                bos.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return file.toString();
    }

    /**
     * 将原图片存储进SD卡
     *
     * @param bitmap   bitmap
     * @param filePath 图像文件路径
     * @param tag      文件命名开头标志
     */
    public String saveBitmapFile(Bitmap bitmap, String filePath, String tag) {
        BufferedOutputStream bos = null;
        String path = "";
        try {
            File file = new File(filePath, pictureName(tag));
            file.createNewFile();
            path = file.toString();
            bos = new BufferedOutputStream(new FileOutputStream(file));
            //参2 ： 保存图像质量
            bitmap.compress(Bitmap.CompressFormat.JPEG, 80, bos);
            bos.flush();
            bos.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        return path;
    }

    /**
     * 返回一个文件命名
     *
     * @param tag
     * @return
     */
    public static String pictureName(String tag) {
        String str = tag + "_";
        StringBuilder sb = new StringBuilder();
        sb.append(str);
        Time time = new Time();
        time.setToNow(); // 取得系统时间。
        sb.append(time.year);
        int month = time.month + 1;
        int date = time.monthDay;
        if (month < 10) {
            sb.append("0" + month);
        } else {
            sb.append(month);
        }
        if (date < 10) {
            sb.append("0" + date + "_" + getFourRandom());
        } else {
            sb.append(date + "_" + getFourRandom());
        }
        sb.append(".jpg");
        return sb.toString();
    }

    /**
     * 产生4位随机数(0000-9999)
     *
     * @return 4位随机数
     */
    public static String getFourRandom() {
        Random random = new Random();
        String fourRandom = random.nextInt(10000) + "";
        int randLength = fourRandom.length();
        if (randLength < 4) {
            for (int i = 1; i <= 4 - randLength; i++)
                fourRandom = "0" + fourRandom;
        }
        return fourRandom;
    }

    /**
     * 将授权文件从assets目录下获取，并且保存到data/data/包名 目录下
     *
     * @param context
     */
    public static void initLicenseFile(Context context, String licenseId) {
        //写入到内置存储应用包名缓存目录下
        File targetFile = new File(context.getCacheDir(), licenseId);
        //如果这个授权文件不存在，或者已存在需要更新时，将授权文件写入手机目录
        if (targetFile.exists()) targetFile.delete();
        InputStream myInput = null;
        OutputStream myOutput = null;
        try {
            myInput = context.getAssets().open(licenseId);
            myOutput = new FileOutputStream(targetFile);
            byte[] buffer = new byte[1024];
            int length;
            while ((length = myInput.read(buffer)) > 0) {
                myOutput.write(buffer, 0, length);
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try {
                if (myInput!=null&&myOutput!=null) {
                    myOutput.flush();
                    myOutput.close();
                    myInput.close();
                }
            } catch (IOException e) {
                e.fillInStackTrace();
            }
        }

    }


    /**
     * 压缩保存图片
     */
    public static void saveBitmapFile(byte[] data, String filePath, int srcWidth, int srcHeight) {
        try {
            File file = new File(filePath);
            BitmapFactory.Options options = new BitmapFactory.Options();
            // 这里我们通过我们的计算算法来得到一个采样率
            options.inSampleSize = computeSize(srcWidth, srcHeight);

            FileOutputStream fos = new FileOutputStream(file);
            Bitmap bitmap = BitmapFactory.decodeByteArray(data, 0, data.length, options);
            //参2 ： 保存图像质量
            bitmap.compress(Bitmap.CompressFormat.JPEG, 75, fos);
            fos.flush();
            fos.close();
            if (bitmap != null) {
                bitmap.recycle();
                bitmap = null;
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    /**
     * 这里的算法是以短边压缩到1000~2000之间为目标，通过计算到1000的比值，然后需要将采样率控制为2的倍数
     * 所以需要使用方法{@link #calInSampleSize(int)}进行计算
     *
     * @return 采样率
     */
    public static int computeSize(int srcWidth, int srcHeight) {
        srcWidth = srcWidth % 2 == 1 ? srcWidth + 1 : srcWidth;
        srcHeight = srcHeight % 2 == 1 ? srcHeight + 1 : srcHeight;

        int shortSide = Math.min(srcWidth, srcHeight);

        int rate = (int) Math.floor(shortSide / 1000.0);

        return calInSampleSize(rate);
    }

    /**
     * 通过移位操作计算采样率，是某个整数对应的二进制数保留最高位为1，其他位置为0的结果
     *
     * @param rate 比例
     * @return 采样率
     */
    private static int calInSampleSize(int rate) {
        int i = 0;
        while ((rate >> (++i)) != 0) ;
        return 1 << --i;
    }
}
