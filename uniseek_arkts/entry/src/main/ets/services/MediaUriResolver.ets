import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { dataSharePredicates } from '@kit.ArkData'
import { fileIo } from '@kit.CoreFileKit'
import { FileTransferPolicy } from './FileTransferPolicy'

export interface CacheFileInfo {
  cachePath: string
  uploadUri: string
  fileName: string
}

class ImageDataHandler implements photoAccessHelper.MediaAssetDataHandler<ArrayBuffer> {
  private readonly resolveData: (data: ArrayBuffer) => void
  private readonly rejectData: (error: Error) => void

  constructor(resolveData: (data: ArrayBuffer) => void, rejectData: (error: Error) => void) {
    this.resolveData = resolveData
    this.rejectData = rejectData
  }

  onDataPrepared(data: ArrayBuffer): void {
    if (data === undefined) {
      this.rejectData(new Error('无法读取所选图片'))
      return
    }
    this.resolveData(data)
  }
}

export class MediaUriResolver {
  static async copyMediaUriToCache(uri: string): Promise<CacheFileInfo> {
    const context = getContext()
    const photoHelper = photoAccessHelper.getPhotoAccessHelper(context)
    const predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates()
    predicates.equalTo(photoAccessHelper.PhotoKeys.URI, uri)
    const fetchOptions: photoAccessHelper.FetchOptions = {
      fetchColumns: [],
      predicates: predicates
    }
    const fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> =
      await photoHelper.getAssets(fetchOptions)

    try {
      const asset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject()
      if (!asset) {
        throw new Error('找不到所选图片')
      }
      const fileName: string = FileTransferPolicy.extractFileName(asset.displayName || uri, 'upload.jpg')
      const cacheName: string = 'uniseek-media-' + new Date().getTime().toString() + '-' + fileName
      const cachePath: string = context.cacheDir + '/' + cacheName
      const imageData: ArrayBuffer = await new Promise<ArrayBuffer>((resolve, reject) => {
        const handler: ImageDataHandler = new ImageDataHandler(resolve, reject)
        const requestOptions: photoAccessHelper.RequestOptions = {
          deliveryMode: photoAccessHelper.DeliveryMode.HIGH_QUALITY_MODE
        }
        photoAccessHelper.MediaAssetManager.requestImageData(context, asset, requestOptions, handler)
          .catch(() => {
            reject(new Error('无法读取所选图片'))
          })
      })

      const outputFile: fileIo.File = fileIo.openSync(cachePath,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC)
      try {
        fileIo.writeSync(outputFile.fd, imageData)
      } finally {
        fileIo.closeSync(outputFile)
      }

      return {
        cachePath: cachePath,
        uploadUri: 'internal://cache/' + cacheName,
        fileName: fileName
      }
    } finally {
      fetchResult.close()
    }
  }
}
