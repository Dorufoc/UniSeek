export interface District {
  name: string
}

export interface City {
  name: string
  districts: District[]
}

export interface Province {
  name: string
  isMunicipality: boolean
  cities: City[]
}

export interface Occupation {
  name: string
}

export interface Field {
  name: string
  occupations: Occupation[]
}

const MOCK_PROVINCES: Province[] = [
  {
    name: '北京', isMunicipality: true,
    cities: [{
      name: '北京', districts: [
        { name: '海淀区' }, { name: '朝阳区' }, { name: '东城区' },
        { name: '西城区' }, { name: '丰台区' }, { name: '通州区' },
        { name: '大兴区' }, { name: '昌平区' }
      ]
    }]
  },
  {
    name: '上海', isMunicipality: true,
    cities: [{
      name: '上海', districts: [
        { name: '浦东新区' }, { name: '黄浦区' }, { name: '徐汇区' },
        { name: '静安区' }, { name: '长宁区' }, { name: '虹口区' },
        { name: '杨浦区' }, { name: '宝山区' }
      ]
    }]
  },
  {
    name: '天津', isMunicipality: true,
    cities: [{
      name: '天津', districts: [
        { name: '和平区' }, { name: '河东区' }, { name: '河西区' },
        { name: '南开区' }, { name: '河北区' }, { name: '滨海新区' }
      ]
    }]
  },
  {
    name: '重庆', isMunicipality: true,
    cities: [{
      name: '重庆', districts: [
        { name: '渝中区' }, { name: '江北区' }, { name: '南岸区' },
        { name: '沙坪坝区' }, { name: '九龙坡区' }, { name: '渝北区' }
      ]
    }]
  },
  {
    name: '广东', isMunicipality: false,
    cities: [
      {
        name: '广州', districts: [
          { name: '天河区' }, { name: '越秀区' }, { name: '海珠区' },
          { name: '白云区' }, { name: '番禺区' }, { name: '南沙区' }
        ]
      },
      {
        name: '深圳', districts: [
          { name: '南山区' }, { name: '福田区' }, { name: '罗湖区' },
          { name: '宝安区' }, { name: '龙岗区' }, { name: '龙华区' }
        ]
      },
      {
        name: '东莞', districts: [
          { name: '莞城区' }, { name: '南城区' }, { name: '万江区' },
          { name: '虎门镇' }
        ]
      }
    ]
  },
  {
    name: '浙江', isMunicipality: false,
    cities: [
      {
        name: '杭州', districts: [
          { name: '西湖区' }, { name: '上城区' }, { name: '拱墅区' },
          { name: '滨江区' }, { name: '余杭区' }, { name: '萧山区' }
        ]
      },
      {
        name: '宁波', districts: [
          { name: '海曙区' }, { name: '鄞州区' }, { name: '江北区' },
          { name: '北仑区' }
        ]
      }
    ]
  },
  {
    name: '江苏', isMunicipality: false,
    cities: [
      {
        name: '南京', districts: [
          { name: '玄武区' }, { name: '秦淮区' }, { name: '建邺区' },
          { name: '鼓楼区' }, { name: '栖霞区' }, { name: '江宁区' }
        ]
      },
      {
        name: '苏州', districts: [
          { name: '姑苏区' }, { name: '吴中区' }, { name: '相城区' },
          { name: '虎丘区' }, { name: '吴江区' }
        ]
      }
    ]
  },
  {
    name: '四川', isMunicipality: false,
    cities: [
      {
        name: '成都', districts: [
          { name: '锦江区' }, { name: '青羊区' }, { name: '金牛区' },
          { name: '武侯区' }, { name: '成华区' }, { name: '高新区' }
        ]
      }
    ]
  },
  {
    name: '湖北', isMunicipality: false,
    cities: [
      {
        name: '武汉', districts: [
          { name: '武昌区' }, { name: '江汉区' }, { name: '硚口区' },
          { name: '汉阳区' }, { name: '洪山区' }, { name: '东湖高新区' }
        ]
      }
    ]
  },
  {
    name: '陕西', isMunicipality: false,
    cities: [
      {
        name: '西安', districts: [
          { name: '雁塔区' }, { name: '碑林区' }, { name: '莲湖区' },
          { name: '未央区' }, { name: '长安区' }, { name: '高新区' }
        ]
      }
    ]
  }
]

const MOCK_FIELDS: Field[] = [
  {
    name: '互联网/IT',
    occupations: [
      { name: '前端工程师' }, { name: '后端工程师' }, { name: '移动开发' },
      { name: '测试工程师' }, { name: '运维工程师' }, { name: '产品经理' },
      { name: 'UI设计师' }, { name: '数据分析师' }, { name: '算法工程师' }
    ]
  },
  {
    name: '金融',
    occupations: [
      { name: '投资银行' }, { name: '风险管理' }, { name: '金融产品经理' },
      { name: '证券分析师' }, { name: '保险精算' }, { name: '合规风控' }
    ]
  },
  {
    name: '教育',
    occupations: [
      { name: '教师' }, { name: '教务管理' }, { name: '课程顾问' },
      { name: '教研员' }, { name: '留学顾问' }, { name: '在线教育运营' }
    ]
  },
  {
    name: '医疗',
    occupations: [
      { name: '临床医生' }, { name: '护士' }, { name: '药剂师' },
      { name: '医疗器械工程师' }, { name: '临床研究协调员' }, { name: '医疗信息化' }
    ]
  },
  {
    name: '制造业',
    occupations: [
      { name: '机械工程师' }, { name: '电气工程师' }, { name: '生产管理' },
      { name: '质量工程师' }, { name: '工艺工程师' }
    ]
  },
  {
    name: '房地产',
    occupations: [
      { name: '土建工程师' }, { name: '项目经理' }, { name: '成本控制' },
      { name: '置业顾问' }, { name: '物业管理' }
    ]
  },
  {
    name: '传媒',
    occupations: [
      { name: '新媒体运营' }, { name: '内容编辑' }, { name: '视频编导' },
      { name: '广告策划' }, { name: '品牌公关' }
    ]
  },
  {
    name: '消费品',
    occupations: [
      { name: '市场营销' }, { name: '品牌管理' }, { name: '供应链管理' },
      { name: '销售代表' }, { name: '电商运营' }
    ]
  }
]

export class DataService {
  static getProvinces(): Province[] {
    return MOCK_PROVINCES
  }

  static getFields(): Field[] {
    return MOCK_FIELDS
  }

  static getProvinceByName(name: string): Province | undefined {
    return MOCK_PROVINCES.find(p => p.name === name)
  }

  static getFieldByName(name: string): Field | undefined {
    return MOCK_FIELDS.find(f => f.name === name)
  }

  static getCitiesByProvince(provinceName: string): City[] {
    const province = MOCK_PROVINCES.find(p => p.name === provinceName)
    return province?.cities || []
  }

  static getDistrictsByCity(provinceName: string, cityName: string): District[] {
    const province = MOCK_PROVINCES.find(p => p.name === provinceName)
    const city = province?.cities.find(c => c.name === cityName)
    return city?.districts || []
  }

  static getOccupationsByField(fieldName: string): Occupation[] {
    const field = MOCK_FIELDS.find(f => f.name === fieldName)
    return field?.occupations || []
  }

  // 后续对接后端 API 时，将以上方法替换为 HTTP 请求
  // 例如：
  // static async getProvincesFromApi(): Promise<Province[]> {
  //   const resp = await http.request('https://api.uniseek.com/regions/provinces')
  //   return JSON.parse(resp.result) as Province[]
  // }
}
