import { describe, it, expect } from '@ohos/hypium'
import { RegionPathBuilder, RegionPathNode } from '../main/ets/common/RegionPathBuilder'

/**
 * 地区路径构建工具单元测试
 * 覆盖：普通省市区、直辖市折叠、省级 ID、未知 ID、空 ID。
 */
export default function regionPathBuilderTest(): void {
  // 构造与 DataService fallback 一致的测试树
  const beijingDistricts: RegionPathNode[] = [
    new RegionPathNode(110101, '东城区', []),
    new RegionPathNode(110105, '朝阳区', [])
  ]
  const beijingCities: RegionPathNode[] = [new RegionPathNode(110100, '北京市', beijingDistricts)]
  const guangzhouDistricts: RegionPathNode[] = [
    new RegionPathNode(440103, '荔湾区', []),
    new RegionPathNode(440106, '天河区', [])
  ]
  const shenzhenDistricts: RegionPathNode[] = [
    new RegionPathNode(440303, '罗湖区', []),
    new RegionPathNode(440305, '南山区', [])
  ]
  const guangdongCities: RegionPathNode[] = [
    new RegionPathNode(440100, '广州市', guangzhouDistricts),
    new RegionPathNode(440300, '深圳市', shenzhenDistricts)
  ]
  const zhejiangCities: RegionPathNode[] = [
    new RegionPathNode(330100, '杭州市', [
      new RegionPathNode(330106, '西湖区', []),
      new RegionPathNode(330108, '滨江区', [])
    ])
  ]
  const regionTree: RegionPathNode[] = [
    new RegionPathNode(110000, '北京市', beijingCities),
    new RegionPathNode(440000, '广东省', guangdongCities),
    new RegionPathNode(330000, '浙江省', zhejiangCities)
  ]

  describe('RegionPathBuilder 生成完整地区路径', (): void => {
    it('普通省市区返回省市区拼接', 0, (): void => {
      expect(RegionPathBuilder.buildPathById(regionTree, 330106)).assertEqual('浙江省杭州市西湖区')
    })

    it('直辖市相邻层级同名时折叠', 0, (): void => {
      expect(RegionPathBuilder.buildPathById(regionTree, 110105)).assertEqual('北京市朝阳区')
    })

    it('省级 ID 仅返回省份名称', 0, (): void => {
      expect(RegionPathBuilder.buildPathById(regionTree, 440000)).assertEqual('广东省')
    })

    it('未知 ID 返回空字符串', 0, (): void => {
      expect(RegionPathBuilder.buildPathById(regionTree, 999999)).assertEqual('')
    })

    it('空 ID 返回空字符串', 0, (): void => {
      expect(RegionPathBuilder.buildPathById(regionTree, 0)).assertEqual('')
    })
  })
}
