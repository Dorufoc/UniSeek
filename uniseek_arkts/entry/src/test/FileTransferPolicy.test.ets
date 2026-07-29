import { describe, it, expect } from '@ohos/hypium';
import { FileTransferPolicy, UploadResponse } from '../main/ets/services/FileTransferPolicy';

export default function fileTransferPolicyTest(): void {
  describe('FileTransferPolicy', (): void => {
    // 文件名提取直接影响缓存文件名与上传配置中的 filename，因此需覆盖 Picker URI 场景
    it('从 PhotoViewPicker 返回的 URI 中提取文件名时忽略查询参数', 0, (): void => {
      const uri: string = 'file://media/photo/1/avatar.jpg?key=value&token=abc'
      expect(FileTransferPolicy.extractFileName(uri, 'fallback.jpg')).assertEqual('avatar.jpg')
    })

    it('URI 中的文件名经 URL 解码后返回', 0, (): void => {
      const uri: string = 'file://media/photo/1/%E5%A4%B4%E5%83%8F.png'
      expect(FileTransferPolicy.extractFileName(uri, 'fallback.png')).assertEqual('头像.png')
    })

    it('URI 不带扩展名时使用兜底文件名', 0, (): void => {
      const uri: string = 'file://media/photo/1/noextension'
      expect(FileTransferPolicy.extractFileName(uri, 'fallback.jpg')).assertEqual('fallback.jpg')
    })

    it('空 URI 使用兜底文件名', 0, (): void => {
      expect(FileTransferPolicy.extractFileName('', 'fallback.pdf')).assertEqual('fallback.pdf')
    })

    it('识别常见图片 MIME 类型', 0, (): void => {
      expect(FileTransferPolicy.getMimeType('photo.JPG')).assertEqual('image/jpeg')
      expect(FileTransferPolicy.getMimeType('photo.png')).assertEqual('image/png')
      expect(FileTransferPolicy.getMimeType('photo.webp')).assertEqual('image/webp')
    })

    it('识别 PDF MIME 类型', 0, (): void => {
      expect(FileTransferPolicy.getMimeType('resume.pdf')).assertEqual('application/pdf')
    })

    it('未知扩展名返回二进制流类型', 0, (): void => {
      expect(FileTransferPolicy.getMimeType('archive.xyz')).assertEqual('application/octet-stream')
    })

    it('读取上传成功响应中的文件地址', 0, (): void => {
      const response: UploadResponse = {
        code: 200,
        message: 'success',
        data: { url: '/upload/avatar.jpg' }
      }
      expect(FileTransferPolicy.readUploadUrl(response)).assertEqual('/upload/avatar.jpg')
    })

    it('上传失败响应返回空地址', 0, (): void => {
      const response: UploadResponse = {
        code: 500,
        message: '上传失败',
        data: { url: 'should-ignore' }
      }
      expect(FileTransferPolicy.readUploadUrl(response)).assertEqual('')
    })
  })
}
