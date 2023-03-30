
import { NativeModules, Platform} from 'react-native';
import {toast} from '../utils'
// import {toast, showLoading, dismissLoading} from "../../utils";
/**
 *
 * @param base64
 * @param type  1:微信好友  2:朋友圈
 */
export const shareToWechat = (base64, type) => {
    if(Platform.OS === 'android') {
        NativeModules.WechatShareModule.shareToWechat(base64, type);
    } else {
        NativeModules.WeixinManager.shareToWechat(base64, type);
    }
};

export const shareFileToWechat = (name, url) => {
  if(Platform.OS === 'android') {
      NativeModules.WechatShareModule.shareFileToWechat(name, url);
  } else {
    //   NativeModules.WeixinManager.shareToWechat(base64, type);
      NativeModules.WeixinManager.shareToWechat(url, name);
   
  }
};


