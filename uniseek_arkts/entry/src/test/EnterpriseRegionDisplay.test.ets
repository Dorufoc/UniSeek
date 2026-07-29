import { describe, it, expect } from '@ohos/hypium'
import { resolveEnterpriseRegionName, RegionFallbackOption } from '../main/ets/common/EnterpriseRegionDisplay'
import { RegionPathNode } from '../main/ets/common/RegionPathBuilder'

/**
 * 企业资质页面地区解析单元测试
 * 覆盖：普通省市区、直辖市折叠、省级 ID、未知 ID 的兜底标签、空 ID。
 */
export default function enterpriseRegionDisplayTest(): void {
  // 构造与 RegionPathBuilder 测试一致的地区树
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
  const regionTree: RegionPathNode[] = [
    new RegionPathNode(110000, '北京市', beijingCities),
    new RegionPathNode(440000, '广东省', guangdongCities)
  ]

  // 模拟 RecruiterEnterprisePage 中 flattenRegions 产生的扁平选项
  const flatOptions: RegionFallbackOption[] = [
    { id: 440000, label: '广东省' },
    { id: 440106, label: '广东省 / 广州市 / 天河区' },
    { id: 999999, label: '其它地区' }
  ]

  describe('企业资质地区显示解析', (): void => {
    it('普通省市区返回省市区拼接路径', 0, (): void => {
      expect(resolveEnterpriseRegionName(440106, regionTree)).assertEqual('广东省广州市天河区')
    })

    it('直辖市相邻层级同名时自动折叠', 0, (): void => {
      expect(resolveEnterpriseRegionName(110105, regionTree)).assertEqual('北京市朝阳区')
    })

    it('省级 ID 仅返回省份名称', 0, (): void => {
      expect(resolveEnterpriseRegionName(440000, regionTree)).assertEqual('广东省')
    })

    it('未知 ID 但在扁平选项中存在时返回兜底标签', 0, (): void => {
      expect(resolveEnterpriseRegionName(999999, regionTree, flatOptions)).assertEqual('其它地区')
    })

    it('未知 ID 且无兜底时返回空字符串', 0, (): void => {
      expect(resolveEnterpriseRegionName(999999, regionTree)).assertEqual('')
    })

    it('空 ID 返回空字符串', 0, (): void => {
      expect(resolveEnterpriseRegionName(0, regionTree)).assertEqual('')
      expect(resolveEnterpriseRegionName(null, regionTree)).assertEqual('')
    })
  })
}
