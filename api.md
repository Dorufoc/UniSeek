# UniSeek 兼职招聘平台 API 接口文档

| 文档名称 | UniSeek API 接口文档 |
|---|---|
| 项目名称 | 基于 Spring Boot 的优寻（UniSeek）兼职招聘平台 |
| 版本号 | V1.2 |
| 编写日期 | 2026-07-13 |
| 基础路径 | `http://{host}:{port}/api` |

---

## 1. 通用约定

### 1.1 请求格式
- 所有请求体使用 `application/json` 格式
- 文件上传使用 `multipart/form-data` 格式
- 字符编码统一使用 `UTF-8`

### 1.2 鉴权方式
- 除注册、登录接口外，所有接口需在请求头携带 JWT Token
- 请求头格式：`Authorization: Bearer {token}`
- Token 有效期：30 分钟

### 1.3 统一响应格式

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {}
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| code | Integer | 状态码，200 表示成功 |
| message | String | 提示信息 |
| data | Object | 响应数据，无数据时为 null |

### 1.4 分页响应格式

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [],
    "total": 100,
    "page": 1,
    "pageSize": 20,
    "totalPages": 5
  }
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| records | Array | 当前页数据列表 |
| total | Long | 总记录数 |
| page | Integer | 当前页码 |
| pageSize | Integer | 每页条数 |
| totalPages | Integer | 总页数 |

### 1.5 通用错误码

| 错误码 | 说明 |
|---|---|
| 200 | 操作成功 |
| 400 | 请求参数错误 |
| 401 | 未认证（Token 无效或已过期） |
| 403 | 无权限访问 |
| 404 | 资源不存在 |
| 409 | 数据冲突（如重复投递） |
| 500 | 服务器内部错误 |

---

## 2. 认证模块（Auth）

### 2.1 用户注册

**接口描述**：手机号 + 邮箱 + 密码注册，注册成功后自动登录并返回 JWT Token。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/auth/register` |
| 鉴权 | 无需鉴权 |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| phone | String | 是 | 手机号（11 位数字，1 开头） |
| email | String | 是 | 邮箱（标准邮箱格式，用于找回密码和通知） |
| password | String | 是 | 密码（6~20 位） |
| confirmPassword | String | 是 | 确认密码（需与 password 一致） |
| nickname | String | 是 | 用户昵称（1~20 位） |
| role | Integer | 是 | 角色：0 求职者 / 1 企业 HR（管理员由后台指定） |

**请求示例**

```json
{
  "phone": "13800138000",
  "email": "zhangsan@example.com",
  "password": "abc123456",
  "confirmPassword": "abc123456",
  "nickname": "张三",
  "role": 0
}
```

**响应示例（成功）**

```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "userInfo": {
      "id": 1,
      "phone": "138****8000",
      "email": "zha***@example.com",
      "nickname": "张三",
      "role": 0,
      "status": 1
    }
  }
}
```

**异常响应**

| 场景 | 响应 |
|---|---|
| 手机号格式错误 | `{ "code": 400, "message": "手机号格式不正确" }` |
| 邮箱格式错误 | `{ "code": 400, "message": "邮箱格式不正确" }` |
| 手机号已注册 | `{ "code": 409, "message": "该手机号已注册" }` |
| 邮箱已注册 | `{ "code": 409, "message": "该邮箱已被注册" }` |
| 密码长度不足 | `{ "code": 400, "message": "密码长度需为 6~20 位" }` |
| 两次密码不一致 | `{ "code": 400, "message": "两次输入的密码不一致" }` |

---

### 2.2 用户登录

**接口描述**：手机号 + 密码登录，校验通过后返回 JWT Token。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/auth/login` |
| 鉴权 | 无需鉴权 |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| phone | String | 是 | 手机号 |
| password | String | 是 | 密码 |

**请求示例**

```json
{
  "phone": "13800138000",
  "password": "abc123456"
}
```

**响应示例（成功）**

```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "userInfo": {
      "id": 1,
      "phone": "138****8000",
      "email": "zha***@example.com",
      "nickname": "张三",
      "role": 0,
      "status": 1
    }
  }
}
```

**异常响应**

| 场景 | 响应 |
|---|---|
| 手机号或密码错误 | `{ "code": 400, "message": "手机号或密码错误" }` |
| 账号已被禁用 | `{ "code": 403, "message": "账号已被禁用，请联系管理员" }` |

---

### 2.3 退出登录

**接口描述**：退出当前登录状态，前端清除 Token。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/auth/logout` |
| 鉴权 | 需要鉴权 |

**请求参数**：无

**响应示例**

```json
{
  "code": 200,
  "message": "退出成功",
  "data": null
}
```

---

### 2.4 获取当前用户信息

**接口描述**：根据 Token 解析用户 ID，返回当前登录用户的基本信息。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/auth/current-user` |
| 鉴权 | 需要鉴权 |

**请求参数**：无

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1,
    "phone": "138****8000",
    "email": "zha***@example.com",
    "nickname": "张三",
    "avatar": null,
    "role": 0,
    "status": 1,
    "creditScore": 100,
    "lastLoginTime": "2026-07-13 10:30:00",
    "createTime": "2026-07-01 09:00:00"
  }
}
```

---

### 2.5 修改密码

**接口描述**：已登录用户修改自己的登录密码。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/auth/password` |
| 鉴权 | 需要鉴权 |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| oldPassword | String | 是 | 原密码 |
| newPassword | String | 是 | 新密码（6~20 位） |
| confirmPassword | String | 是 | 确认新密码 |

**请求示例**

```json
{
  "oldPassword": "abc123456",
  "newPassword": "xyz789012",
  "confirmPassword": "xyz789012"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "密码修改成功",
  "data": null
}
```

---

### 2.6 实名认证

**接口描述**：用户提交真实姓名和身份证号进行实名认证。认证通过后，`t_user` 表的 `real_name` 和 `id_card` 字段被填充，后续投递职位或提交企业资质时不再重复认证。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/auth/real-name` |
| 鉴权 | 需要鉴权 |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| realName | String | 是 | 真实姓名（1~20 位） |
| idCard | String | 是 | 身份证号（18 位，末位可为 X） |

**请求示例**

```json
{
  "realName": "张三",
  "idCard": "110101200001011234"
}
```

**响应示例（成功）**

```json
{
  "code": 200,
  "message": "实名认证成功",
  "data": {
    "realName": "张三",
    "idCard": "110101********1234",
    "authTime": "2026-07-13 10:00:00"
  }
}
```

**异常响应**

| 场景 | 响应 |
|---|---|
| 姓名或身份证号为空 | `{ "code": 400, "message": "姓名和身份证号不能为空" }` |
| 身份证号格式不正确 | `{ "code": 400, "message": "身份证号格式不正确" }` |
| 年龄不足 16 周岁 | `{ "code": 400, "message": "未满16周岁，无法完成实名认证" }` |
| 已实名认证 | `{ "code": 409, "message": "您已完成实名认证，无需重复认证" }` |

**后端校验逻辑**：使用 Hutool `IdcardUtil.isValidCard()` 校验身份证格式与校验码，使用 `IdcardUtil.getAgeByIdCard()` 校验年龄 ≥ 16 周岁。

---

### 2.7 获取实名认证状态

**接口描述**：查询当前用户是否已完成实名认证。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/auth/real-name/status` |
| 鉴权 | 需要鉴权 |

**请求参数**：无

**响应示例（已认证）**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "isAuth": true,
    "realName": "张三",
    "idCard": "110101********1234"
  }
}
```

**响应示例（未认证）**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "isAuth": false,
    "realName": null,
    "idCard": null
  }
}
```

---

## 3. 用户模块（User）

### 3.1 更新个人资料

**接口描述**：更新当前登录用户的昵称、头像等基本信息。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/user/profile` |
| 鉴权 | 需要鉴权 |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| nickname | String | 否 | 昵称（1~20 位） |
| avatar | String | 否 | 头像 URL |

**请求示例**

```json
{
  "nickname": "张三丰",
  "avatar": "https://cdn.uniseek.com/avatars/1.jpg"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "更新成功",
  "data": {
    "id": 1,
    "nickname": "张三丰",
    "avatar": "https://cdn.uniseek.com/avatars/1.jpg"
  }
}
```

---

## 4. 简历模块（Resume）

### 4.1 获取我的简历

**接口描述**：求职者获取自己的在线简历信息。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/resume` |
| 鉴权 | 需要鉴权，角色限制：求职者（0） |
| 权限 | 求职者 |

**请求参数**：无

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1,
    "userId": 1,
    "realName": "张三",
    "gender": 0,
    "birthDate": "2000-01-15",
    "education": "本科",
    "school": "清华大学",
    "skills": "[\"Java\",\"Spring Boot\",\"Vue\"]",
    "experience": "<p>曾在某公司担任实习生...</p>",
    "attachmentUrl": "https://cdn.uniseek.com/resumes/1.pdf",
    "updateTime": "2026-07-10 14:00:00"
  }
}
```

---

### 4.2 创建/更新简历

**接口描述**：求职者创建或更新在线简历。若简历不存在则创建，存在则更新。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/resume` |
| 鉴权 | 需要鉴权，角色限制：求职者（0） |
| 权限 | 求职者 |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| realName | String | 否 | 真实姓名 |
| gender | Integer | 否 | 性别：0 男 / 1 女 |
| birthDate | String | 否 | 出生日期（yyyy-MM-dd） |
| education | String | 否 | 学历 |
| school | String | 否 | 毕业院校 |
| skills | String | 否 | 技能标签（JSON 数组字符串） |
| experience | String | 否 | 工作/实践经历（富文本 HTML） |
| attachmentUrl | String | 否 | 附件简历 URL |

**请求示例**

```json
{
  "realName": "张三",
  "gender": 0,
  "birthDate": "2000-01-15",
  "education": "本科",
  "school": "清华大学",
  "skills": "[\"Java\",\"Spring Boot\",\"Vue\"]",
  "experience": "<p>曾在某公司担任实习生，负责...</p>"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "简历保存成功",
  "data": {
    "id": 1,
    "realName": "张三",
    "gender": 0,
    "birthDate": "2000-01-15",
    "education": "本科",
    "school": "清华大学",
    "skills": "[\"Java\",\"Spring Boot\",\"Vue\"]",
    "experience": "<p>曾在某公司担任实习生，负责...</p>",
    "attachmentUrl": null,
    "updateTime": "2026-07-13 10:00:00"
  }
}
```

---

### 4.3 上传附件简历

**接口描述**：求职者上传 PDF/Word 格式的附件简历。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/resume/upload-attachment` |
| 鉴权 | 需要鉴权，角色限制：求职者（0） |
| 权限 | 求职者 |
| Content-Type | `multipart/form-data` |

**请求参数（Form-Data）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| file | File | 是 | 简历文件，支持 PDF / Word 格式，最大 10MB |

**响应示例**

```json
{
  "code": 200,
  "message": "上传成功",
  "data": {
    "attachmentUrl": "https://cdn.uniseek.com/resumes/1_20260713.pdf"
  }
}
```

---

## 5. 职位分类模块（Category）

### 5.1 获取分类列表

**接口描述**：获取所有职位分类，以树形结构返回。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/categories` |
| 鉴权 | 需要鉴权 |

**请求参数**：无

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 1,
      "parentId": 0,
      "name": "餐饮服务",
      "sortOrder": 1,
      "children": [
        {
          "id": 16,
          "parentId": 1,
          "name": "服务员",
          "sortOrder": 1,
          "children": []
        },
        {
          "id": 17,
          "parentId": 1,
          "name": "后厨帮工",
          "sortOrder": 2,
          "children": []
        }
      ]
    },
    {
      "id": 2,
      "parentId": 0,
      "name": "家教辅导",
      "sortOrder": 2,
      "children": []
    }
  ]
}
```

---

## 6. 地区数据服务模块（Region）

> 平台内置全国行政区划数据（省/市/区三级，GB/T 2260 标准），通过 `region` 表提供统一的地区数据服务，支持职位发布时选择工作地区、职位搜索时按地区筛选。

### 6.1 获取所有省级行政区划

**接口描述**：获取所有省级行政区划列表。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/region/provinces` |
| 鉴权 | 无需鉴权 |

**请求参数**：无

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 110000,
      "name": "北京市",
      "level": 1
    },
    {
      "id": 120000,
      "name": "天津市",
      "level": 1
    },
    {
      "id": 310000,
      "name": "上海市",
      "level": 1
    }
  ]
}
```

| 响应字段 | 类型 | 说明 |
|---|---|---|
| id | Long | 行政区划代码 |
| name | String | 行政区划名称 |
| level | Integer | 层级：1 省 / 2 市 / 3 区县 |

---

### 6.2 获取子级行政区划

**接口描述**：获取指定父级下的子级行政区划列表。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/region/children/{parentId}` |
| 鉴权 | 无需鉴权 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| parentId | Long | 父级行政区划 ID |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 110101,
      "name": "东城区",
      "level": 3
    },
    {
      "id": 110102,
      "name": "西城区",
      "level": 3
    },
    {
      "id": 110105,
      "name": "朝阳区",
      "level": 3
    }
  ]
}
```

---

### 6.3 获取完整省/市/区三级树形结构

**接口描述**：获取完整的省/市/区三级树形结构，用于级联选择器。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/region/tree` |
| 鉴权 | 无需鉴权 |

**请求参数**：无

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 110000,
      "name": "北京市",
      "level": 1,
      "children": [
        {
          "id": 110100,
          "name": "北京市",
          "level": 2,
          "children": [
            { "id": 110101, "name": "东城区", "level": 3 },
            { "id": 110102, "name": "西城区", "level": 3 },
            { "id": 110105, "name": "朝阳区", "level": 3 }
          ]
        }
      ]
    }
  ]
}
```

| 响应字段 | 类型 | 说明 |
|---|---|---|
| id | Long | 行政区划代码 |
| name | String | 行政区划名称 |
| level | Integer | 层级：1 省 / 2 市 / 3 区县 |
| children | Array | 子级区划列表（仅省级和市级节点包含） |

**数据规模说明**：数据基于 GB/T 2260 标准，种子数据共 3432 条记录（34 个省 + 342 个市 + 3056 个区县）。

---

## 7. 职位模块（Task）

### 7.1 职位列表（搜索 & 筛选）

**接口描述**：分页查询职位列表，支持关键词搜索、分类筛选、薪资筛选、地点筛选、排序。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/tasks` |
| 鉴权 | 需要鉴权 |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| keyword | String | 否 | 搜索关键词（匹配职位标题） |
| categoryId | Long | 否 | 分类 ID |
| regionId | Long | 否 | 工作地区 ID（区县级） |
| jobType | Integer | 否 | 岗位类型：1 全职 / 2 兼职 / 3 实习 |
| salaryMin | BigDecimal | 否 | 最低薪资 |
| salaryMax | BigDecimal | 否 | 最高薪资 |
| salaryUnit | Integer | 否 | 薪资单位：0 日结 / 1 时薪 / 2 月结 |
| address | String | 否 | 工作地点（模糊搜索） |
| sortBy | String | 否 | 排序字段：create_time（最新）/ salary_max（薪资）/ 默认按 create_time |
| sortOrder | String | 否 | 排序方向：asc / desc（默认 desc） |
| page | Integer | 否 | 页码（默认 1） |
| pageSize | Integer | 否 | 每页条数（默认 20，最大 100） |

**请求示例**

```
GET /api/tasks?keyword=服务员&categoryId=1&salaryMin=100&salaryMax=300&page=1&pageSize=20
```

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "enterpriseId": 1,
        "enterpriseName": "某某餐饮有限公司",
        "categoryId": 16,
        "categoryName": "服务员",
        "regionId": 110105,
        "regionName": "北京市朝阳区",
        "title": "周末餐厅服务员",
        "salaryMin": 150.00,
        "salaryMax": 200.00,
        "salaryUnit": 0,
        "jobType": 2,
        "totalQuota": 5,
        "remainingQuota": 3,
        "address": "北京市朝阳区某某路 100 号",
        "status": 1,
        "deadline": "2026-07-20 23:59:59",
        "createTime": "2026-07-10 10:00:00"
      }
    ],
    "total": 100,
    "page": 1,
    "pageSize": 20,
    "totalPages": 5
  }
}
```

---

### 6.2 职位详情

**接口描述**：获取单个职位的完整信息。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/tasks/{id}` |
| 鉴权 | 需要鉴权 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 职位 ID |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1,
    "enterpriseId": 1,
    "enterpriseName": "某某餐饮有限公司",
    "enterpriseIndustry": "餐饮",
    "categoryId": 16,
    "categoryName": "服务员",
    "regionId": 110105,
    "regionName": "北京市朝阳区",
    "title": "周末餐厅服务员",
    "description": "<p>负责餐厅日常服务工作...</p>",
    "salaryMin": 150.00,
    "salaryMax": 200.00,
    "salaryUnit": 0,
    "jobType": 2,
    "totalQuota": 5,
    "remainingQuota": 3,
    "address": "北京市朝阳区某某路 100 号",
    "longitude": 116.4612345,
    "latitude": 39.9012345,
    "status": 1,
    "deadline": "2026-07-20 23:59:59",
    "createTime": "2026-07-10 10:00:00",
    "updateTime": "2026-07-10 10:00:00",
    "hasApplied": false
  }
}
```

---

### 6.3 发布职位

**接口描述**：企业 HR 发布新职位，提交后状态为「待审核」。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/tasks` |
| 鉴权 | 需要鉴权，角色限制：企业 HR（1） |
| 权限 | 企业 HR（需企业资质已认证） |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| categoryId | Long | 是 | 分类 ID |
| regionId | Long | 否 | 工作地区 ID（区县级） |
| title | String | 是 | 职位标题（1~100 位） |
| description | String | 是 | 职位描述（富文本 HTML） |
| salaryMin | BigDecimal | 是 | 薪资范围最低值 |
| salaryMax | BigDecimal | 是 | 薪资范围最高值 |
| salaryUnit | Integer | 是 | 薪资单位：0 日结 / 1 时薪 / 2 月结 |
| jobType | Integer | 是 | 岗位类型：1 全职 / 2 兼职 / 3 实习 |
| totalQuota | Integer | 是 | 招聘总人数（≥1） |
| address | String | 否 | 工作地址 |
| longitude | BigDecimal | 否 | 经度 |
| latitude | BigDecimal | 否 | 纬度 |
| deadline | String | 否 | 报名截止时间（yyyy-MM-dd HH:mm:ss） |

**请求示例**

```json
{
  "categoryId": 16,
  "regionId": 110105,
  "title": "周末餐厅服务员",
  "description": "<p>负责餐厅日常服务工作...</p>",
  "salaryMin": 150.00,
  "salaryMax": 200.00,
  "salaryUnit": 0,
  "jobType": 2,
  "totalQuota": 5,
  "address": "北京市朝阳区某某路 100 号",
  "longitude": 116.4612345,
  "latitude": 39.9012345,
  "deadline": "2026-07-20 23:59:59"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "职位发布成功，等待审核",
  "data": {
    "id": 1,
    "status": 0,
    "createTime": "2026-07-13 10:00:00"
  }
}
```

**异常响应**

| 场景 | 响应 |
|---|---|
| 企业未认证 | `{ "code": 403, "message": "企业资质未认证，无法发布职位" }` |

---

### 6.4 更新职位

**接口描述**：企业 HR 更新自己发布的职位信息（仅限「待审核」或「已下架」状态的职位）。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/tasks/{id}` |
| 鉴权 | 需要鉴权，角色限制：企业 HR（1） |
| 权限 | 仅限本企业发布的职位 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 职位 ID |

**请求参数（Body）**：同 6.3 发布职位

**响应示例**

```json
{
  "code": 200,
  "message": "职位更新成功",
  "data": {
    "id": 1,
    "updateTime": "2026-07-13 11:00:00"
  }
}
```

---

### 6.5 修改职位状态

**接口描述**：企业 HR 下架自己的职位，或管理员强制下架/审核职位。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/tasks/{id}/status` |
| 鉴权 | 需要鉴权 |
| 权限 | 企业 HR：仅可下架本企业职位（→ 4）；管理员：可审核（→ 1）或下架（→ 4） |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 职位 ID |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| status | Integer | 是 | 目标状态：1 审核通过（管理员）/ 4 下架 |
| reason | String | 否 | 操作原因（下架时必填） |

**请求示例**

```json
{
  "status": 4,
  "reason": "招聘名额已满，提前下架"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "状态更新成功",
  "data": {
    "id": 1,
    "status": 4,
    "updateTime": "2026-07-13 12:00:00"
  }
}
```

---

### 6.6 本企业职位列表

**接口描述**：企业 HR 查看本企业发布的所有职位。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/enterprise/tasks` |
| 鉴权 | 需要鉴权，角色限制：企业 HR（1） |
| 权限 | 企业 HR |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| status | Integer | 否 | 筛选状态：0 待审 / 1 招聘中 / 2 已满员 / 3 已过期 / 4 已下架 |
| page | Integer | 否 | 页码（默认 1） |
| pageSize | Integer | 否 | 每页条数（默认 20） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "title": "周末餐厅服务员",
        "categoryName": "服务员",
        "regionName": "北京市朝阳区",
        "status": 1,
        "jobType": 2,
        "totalQuota": 5,
        "remainingQuota": 3,
        "applicationCount": 12,
        "createTime": "2026-07-10 10:00:00"
      }
    ],
    "total": 5,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  }
}
```

---

## 8. 投递模块（Application）

### 8.1 投递职位

**接口描述**：求职者对职位进行投递，系统生成简历快照并创建投递记录。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/applications` |
| 鉴权 | 需要鉴权，角色限制：求职者（0） |
| 权限 | 求职者 |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| taskId | Long | 是 | 职位 ID |

**请求示例**

```json
{
  "taskId": 1
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "投递成功",
  "data": {
    "id": 1,
    "taskId": 1,
    "status": 0,
    "createTime": "2026-07-13 10:00:00"
  }
}
```

**异常响应**

| 场景 | 响应 |
|---|---|
| 简历未填写 | `{ "code": 400, "message": "请先完善您的在线简历" }` |
| 已投递过该职位 | `{ "code": 409, "message": "您已投递过该职位，请勿重复投递" }` |
| 职位不在招聘中 | `{ "code": 400, "message": "该职位当前不可投递" }` |
| 职位已满员 | `{ "code": 400, "message": "该职位已满员" }` |

---

### 8.2 我的投递记录

**接口描述**：求职者查看自己的所有投递记录及状态。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/applications/my` |
| 鉴权 | 需要鉴权，角色限制：求职者（0） |
| 权限 | 求职者 |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| status | Integer | 否 | 筛选状态：0 已投递 / 1 待面试 / 2 待定 / 3 已录用 / 4 已淘汰 / 5 已完成 |
| page | Integer | 否 | 页码（默认 1） |
| pageSize | Integer | 否 | 每页条数（默认 20） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "taskId": 1,
        "taskTitle": "周末餐厅服务员",
        "enterpriseName": "某某餐饮有限公司",
        "status": 0,
        "interviewTime": null,
        "interviewLocation": null,
        "createTime": "2026-07-13 10:00:00",
        "updateTime": "2026-07-13 10:00:00"
      }
    ],
    "total": 10,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  }
}
```

---

### 8.3 投递详情

**接口描述**：查看某条投递记录的完整详情，包括简历快照。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/applications/{id}` |
| 鉴权 | 需要鉴权 |
| 权限 | 求职者：仅限自己的投递；HR：仅限本企业职位的投递；管理员：全部 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 投递记录 ID |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1,
    "taskId": 1,
    "taskTitle": "周末餐厅服务员",
    "taskDescription": "<p>负责餐厅日常服务工作...</p>",
    "enterpriseName": "某某餐饮有限公司",
    "applicantId": 1,
    "applicantName": "张三",
    "resumeSnapshot": {
      "realName": "张三",
      "gender": 0,
      "birthDate": "2000-01-15",
      "education": "本科",
      "school": "清华大学",
      "skills": "[\"Java\",\"Spring Boot\",\"Vue\"]",
      "experience": "<p>曾在某公司担任实习生...</p>"
    },
    "attachmentUrl": "https://cdn.uniseek.com/resumes/1.pdf",
    "status": 0,
    "interviewTime": null,
    "interviewLocation": null,
    "rejectReason": null,
    "hrNote": null,
    "hrId": null,
    "createTime": "2026-07-13 10:00:00",
    "updateTime": "2026-07-13 10:00:00"
  }
}
```

---

### 8.4 职位投递列表（HR 视角）

**接口描述**：企业 HR 查看某个职位的所有投递记录（简历池）。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/tasks/{taskId}/applications` |
| 鉴权 | 需要鉴权，角色限制：企业 HR（1） |
| 权限 | 仅限本企业职位的投递 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| taskId | Long | 职位 ID |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| status | Integer | 否 | 筛选状态 |
| page | Integer | 否 | 页码（默认 1） |
| pageSize | Integer | 否 | 每页条数（默认 20） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "applicantId": 1,
        "applicantName": "张三",
        "applicantEducation": "本科",
        "applicantSchool": "清华大学",
        "status": 0,
        "interviewTime": null,
        "createTime": "2026-07-13 10:00:00"
      }
    ],
    "total": 12,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  }
}
```

---

### 8.5 修改投递状态（HR 处理投递）

**接口描述**：企业 HR 对投递记录进行操作（邀请面试、录用、淘汰、待定等）。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/applications/{id}/status` |
| 鉴权 | 需要鉴权，角色限制：企业 HR（1） |
| 权限 | 仅限本企业职位下的投递 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 投递记录 ID |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| status | Integer | 是 | 目标状态：1 待面试 / 2 待定 / 3 已录用 / 4 已淘汰 |
| interviewTime | String | 条件必填 | 面试时间，状态为 1（待面试）时必填 |
| interviewLocation | String | 条件必填 | 面试地点，状态为 1（待面试）时必填 |
| rejectReason | String | 条件必填 | 淘汰原因，状态为 4（已淘汰）时必填 |
| hrNote | String | 否 | HR 内部备注（求职者不可见） |

**请求示例（邀请面试）**

```json
{
  "status": 1,
  "interviewTime": "2026-07-15 14:00:00",
  "interviewLocation": "北京市朝阳区某某路 100 号 3 楼会议室",
  "hrNote": "该求职者经验丰富，优先面试"
}
```

**请求示例（淘汰）**

```json
{
  "status": 4,
  "rejectReason": "技能不匹配岗位要求",
  "hrNote": "缺乏餐饮行业经验"
}
```

**请求示例（录用）**

```json
{
  "status": 3,
  "hrNote": "面试表现优秀，予以录用"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1,
    "status": 1,
    "interviewTime": "2026-07-15 14:00:00",
    "interviewLocation": "北京市朝阳区某某路 100 号 3 楼会议室",
    "updateTime": "2026-07-13 11:00:00"
  }
}
```

**异常响应**

| 场景 | 响应 |
|---|---|
| 状态流转不合法 | `{ "code": 400, "message": "不允许从当前状态转变到目标状态" }` |
| 并发冲突（乐观锁） | `{ "code": 409, "message": "操作失败，该记录已被其他 HR 修改，请刷新后重试" }` |
| 名额已满 | `{ "code": 400, "message": "该职位名额已满，无法录用" }` |

---

### 8.6 结算确认（已录用 → 已完成）

**接口描述**：企业 HR 对已录用的求职者进行结算确认，将投递状态从"已录用(3)"变更为"已完成(5)"。该操作不可逆。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/applications/{id}/complete` |
| 鉴权 | 需要鉴权，角色限制：企业 HR（1） |
| 权限 | 仅限本企业职位下的投递 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 投递记录 ID |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| settlementAmount | BigDecimal | 否 | 实际结算金额，不传则使用职位薪资范围上限 |
| hrNote | String | 否 | 结算备注 |

**请求示例**

```json
{
  "settlementAmount": 800.00,
  "hrNote": "兼职工作表现优秀，按约定结算"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "结算确认成功",
  "data": {
    "id": 1,
    "status": 5,
    "settlementAmount": 800.00,
    "updateTime": "2026-07-20 18:00:00"
  }
}
```

**异常响应**

| 场景 | 响应 |
|---|---|
| 当前状态不是"已录用" | `{ "code": 400, "message": "仅已录用状态的投递可进行结算确认" }` |
| 并发冲突（乐观锁） | `{ "code": 409, "message": "操作失败，该记录已被其他 HR 修改，请刷新后重试" }` |

---

## 9. 企业模块（Enterprise）

### 9.1 提交企业资质认证

**接口描述**：企业 HR 提交企业资质信息进行认证。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/enterprise` |
| 鉴权 | 需要鉴权，角色限制：企业 HR（1） |
| 权限 | 企业 HR |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| companyName | String | 是 | 公司全称 |
| creditCode | String | 是 | 统一社会信用代码（18 位） |
| licenseImgUrl | String | 是 | 营业执照图片 URL |
| industry | String | 否 | 所属行业 |
| description | String | 否 | 公司简介 |

**请求示例**

```json
{
  "companyName": "某某餐饮有限公司",
  "creditCode": "91110108MA01XXXXX",
  "licenseImgUrl": "https://cdn.uniseek.com/licenses/1.jpg",
  "industry": "餐饮",
  "description": "某某餐饮有限公司成立于 2010 年，主营中式快餐..."
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "资质提交成功，等待审核",
  "data": {
    "id": 1,
    "auditStatus": 0,
    "createTime": "2026-07-13 10:00:00"
  }
}
```

**异常响应**

| 场景 | 响应 |
|---|---|
| 已提交过认证 | `{ "code": 409, "message": "您已提交过企业认证，请勿重复提交" }` |
| 信用代码已存在 | `{ "code": 409, "message": "该统一社会信用代码已被注册" }` |

---

### 9.2 获取我的企业信息

**接口描述**：企业 HR 获取自己关联的企业信息及认证状态。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/enterprise/my` |
| 鉴权 | 需要鉴权，角色限制：企业 HR（1） |
| 权限 | 企业 HR |

**请求参数**：无

**响应示例（未认证）**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": null
}
```

**响应示例（审核中）**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1,
    "companyName": "某某餐饮有限公司",
    "creditCode": "91110108MA01XXXXX",
    "licenseImgUrl": "https://cdn.uniseek.com/licenses/1.jpg",
    "industry": "餐饮",
    "description": "某某餐饮有限公司成立于 2010 年...",
    "auditStatus": 0,
    "createTime": "2026-07-13 10:00:00"
  }
}
```

---

### 9.3 更新企业信息

**接口描述**：企业 HR 更新已认证或已驳回的企业信息，更新后需重新审核。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/enterprise` |
| 鉴权 | 需要鉴权，角色限制：企业 HR（1） |
| 权限 | 企业 HR |

**请求参数（Body）**：同 8.1

**响应示例**

```json
{
  "code": 200,
  "message": "企业信息更新成功，等待审核",
  "data": {
    "id": 1,
    "auditStatus": 0
  }
}
```

---

## 10. 管理员模块（Admin）

### 10.1 企业审核列表

**接口描述**：管理员查看待审核的企业列表。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/admin/enterprises` |
| 鉴权 | 需要鉴权，角色限制：管理员（9） |
| 权限 | 管理员 |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| auditStatus | Integer | 否 | 筛选状态：0 待审 / 1 已认证 / 2 已驳回 |
| page | Integer | 否 | 页码（默认 1） |
| pageSize | Integer | 否 | 每页条数（默认 20） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "userId": 2,
        "contactPhone": "139****9000",
        "companyName": "某某餐饮有限公司",
        "creditCode": "91110108MA01XXXXX",
        "licenseImgUrl": "https://cdn.uniseek.com/licenses/1.jpg",
        "industry": "餐饮",
        "auditStatus": 0,
        "createTime": "2026-07-13 10:00:00"
      }
    ],
    "total": 5,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  }
}
```

---

### 10.2 企业资质审核

**接口描述**：管理员审核企业资质，通过或驳回。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/admin/enterprises/{id}/audit` |
| 鉴权 | 需要鉴权，角色限制：管理员（9） |
| 权限 | 管理员 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 企业 ID |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| auditStatus | Integer | 是 | 审核结果：1 已认证 / 2 驳回 |
| reason | String | 条件必填 | 驳回原因，驳回时必填 |

**请求示例（通过）**

```json
{
  "auditStatus": 1
}
```

**请求示例（驳回）**

```json
{
  "auditStatus": 2,
  "reason": "营业执照图片模糊不清，请重新上传"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "审核完成",
  "data": {
    "id": 1,
    "auditStatus": 1
  }
}
```

---

### 10.3 待审核职位列表

**接口描述**：管理员查看所有待审核的职位。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/admin/tasks/pending` |
| 鉴权 | 需要鉴权，角色限制：管理员（9） |
| 权限 | 管理员 |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| page | Integer | 否 | 页码（默认 1） |
| pageSize | Integer | 否 | 每页条数（默认 20） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "enterpriseName": "某某餐饮有限公司",
        "categoryName": "服务员",
        "title": "周末餐厅服务员",
        "salaryMin": 150.00,
        "salaryMax": 200.00,
        "totalQuota": 5,
        "status": 0,
        "createTime": "2026-07-13 10:00:00"
      }
    ],
    "total": 8,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  }
}
```

---

### 10.4 职位审核

**接口描述**：管理员审核职位，通过或驳回。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/admin/tasks/{id}/audit` |
| 鉴权 | 需要鉴权，角色限制：管理员（9） |
| 权限 | 管理员 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 职位 ID |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| auditStatus | Integer | 是 | 审核结果：1 通过（→ 招聘中）/ 2 驳回 |
| reason | String | 条件必填 | 驳回原因，驳回时必填 |

**请求示例（通过）**

```json
{
  "auditStatus": 1
}
```

**请求示例（驳回）**

```json
{
  "auditStatus": 2,
  "reason": "职位描述中包含不实信息，请修改后重新提交"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "审核完成",
  "data": {
    "id": 1,
    "status": 1
  }
}
```

---

### 10.5 数据统计看板

**接口描述**：管理员查看运营数据统计。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/admin/statistics` |
| 鉴权 | 需要鉴权，角色限制：管理员（9） |
| 权限 | 管理员 |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| startDate | String | 否 | 开始日期（yyyy-MM-dd） |
| endDate | String | 否 | 结束日期（yyyy-MM-dd） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "summary": {
      "totalUsers": 1500,
      "totalEnterprises": 120,
      "totalTasks": 500,
      "totalResumes": 2400,
      "totalDeliveries": 3200,
      "totalInterviews": 450,
      "totalEntries": 180
    },
    "dailyStats": [
      {
        "statDate": "2026-07-12",
        "newUserCount": 45,
        "newEnterpriseCount": 3,
        "newTaskCount": 18,
        "newResumeCount": 56,
        "newDeliveryCount": 120,
        "newInterviewCount": 15,
        "newEntryCount": 8
      },
      {
        "statDate": "2026-07-11",
        "newUserCount": 38,
        "newEnterpriseCount": 2,
        "newTaskCount": 15,
        "newResumeCount": 42,
        "newDeliveryCount": 98,
        "newInterviewCount": 12,
        "newEntryCount": 5
      }
    ]
  }
}
```

---

### 10.6 用户管理列表

**接口描述**：管理员查看平台所有用户。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/admin/users` |
| 鉴权 | 需要鉴权，角色限制：管理员（9） |
| 权限 | 管理员 |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| keyword | String | 否 | 搜索（手机号/昵称） |
| role | Integer | 否 | 角色筛选：0 求职者 / 1 企业 HR |
| status | Integer | 否 | 状态：0 禁用 / 1 正常 |
| page | Integer | 否 | 页码（默认 1） |
| pageSize | Integer | 否 | 每页条数（默认 20） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "phone": "138****8000",
        "email": "zha***@example.com",
        "nickname": "张三",
        "role": 0,
        "status": 1,
        "creditScore": 100,
        "lastLoginTime": "2026-07-13 10:00:00",
        "createTime": "2026-07-01 09:00:00"
      }
    ],
    "total": 1500,
    "page": 1,
    "pageSize": 20,
    "totalPages": 75
  }
}
```

---

### 10.7 禁用/启用用户

**接口描述**：管理员禁用或启用用户账号。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/admin/users/{id}/status` |
| 鉴权 | 需要鉴权，角色限制：管理员（9） |
| 权限 | 管理员 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 用户 ID |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| status | Integer | 是 | 0 禁用 / 1 启用 |

**请求示例**

```json
{
  "status": 0
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1,
    "status": 0
  }
}
```

---

### 10.8 操作审计日志

**接口描述**：管理员查看系统操作审计日志，用于安全追溯。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/admin/operation-logs` |
| 鉴权 | 需要鉴权，角色限制：管理员（9） |
| 权限 | 管理员 |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| operatorId | Long | 否 | 操作人用户 ID |
| operationType | String | 否 | 操作类型（如 LOGIN / REGISTER / APPLY / HIRE / AUDIT 等） |
| targetType | String | 否 | 目标类型（如 USER / TASK / ENTERPRISE / APPLICATION 等） |
| targetId | Long | 否 | 目标 ID |
| startTime | String | 否 | 开始时间（yyyy-MM-dd HH:mm:ss） |
| endTime | String | 否 | 结束时间（yyyy-MM-dd HH:mm:ss） |
| page | Integer | 否 | 页码（默认 1） |
| pageSize | Integer | 否 | 每页条数（默认 20） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "operatorId": 2,
        "operatorName": "李 HR",
        "operationType": "HIRE",
        "targetType": "APPLICATION",
        "targetId": 1,
        "detail": {
          "applicationId": 1,
          "taskId": 1,
          "taskTitle": "周末餐厅服务员",
          "applicantName": "张三",
          "fromStatus": 1,
          "toStatus": 3
        },
        "ipAddress": "192.168.1.100",
        "createTime": "2026-07-13 14:00:00"
      },
      {
        "id": 2,
        "operatorId": 9,
        "operatorName": "系统",
        "operationType": "AUDIT",
        "targetType": "TASK",
        "targetId": 1,
        "detail": {
          "taskId": 1,
          "taskTitle": "周末餐厅服务员",
          "auditResult": "通过",
          "fromStatus": 0,
          "toStatus": 1
        },
        "ipAddress": "192.168.1.1",
        "createTime": "2026-07-13 10:30:00"
      }
    ],
    "total": 156,
    "page": 1,
    "pageSize": 20,
    "totalPages": 8
  }
}
```

| 响应字段 | 类型 | 说明 |
|---|---|---|
| operatorId | Long | 操作人用户 ID（NULL 表示系统操作） |
| operatorName | String | 操作人昵称 |
| operationType | String | 操作类型 |
| targetType | String | 目标类型 |
| targetId | Long | 目标 ID |
| detail | Object | 操作详情（JSON），记录操作前后的状态变更 |
| ipAddress | String | 操作请求 IP 地址 |
| createTime | String | 操作时间 |

**日志记录范围**：所有涉及数据变更的关键操作，包括用户注册/登录、职位发布/审核/下架、投递/录用/淘汰、企业资质审核、投诉处理等。日志写入后不可修改，仅支持查询。

---

## 11. 消息模块（Message）

### 11.1 消息列表

**接口描述**：用户查看自己的站内消息列表。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/messages` |
| 鉴权 | 需要鉴权 |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| type | Integer | 否 | 类型筛选：0 系统通知 / 1 面试邀请 / 2 录用通知 / 3 淘汰通知 |
| isRead | Integer | 否 | 已读状态筛选：0 未读 / 1 已读 |
| page | Integer | 否 | 页码（默认 1） |
| pageSize | Integer | 否 | 每页条数（默认 20） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "title": "面试邀请通知",
        "content": "恭喜您通过初筛，请于 2026-07-15 14:00 参加面试",
        "type": 1,
        "senderId": 2,
        "senderName": "李 HR",
        "isRead": 0,
        "bizId": 1,
        "createTime": "2026-07-13 11:00:00"
      }
    ],
    "total": 5,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  }
}
```

---

### 11.2 未读消息数

**接口描述**：获取当前用户未读消息总数。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/messages/unread-count` |
| 鉴权 | 需要鉴权 |

**请求参数**：无

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "totalUnread": 5,
    "systemUnread": 1,
    "interviewUnread": 2,
    "offerUnread": 1,
    "rejectUnread": 1
  }
}
```

---

### 11.3 标记消息已读

**接口描述**：将指定消息标记为已读。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/messages/{id}/read` |
| 鉴权 | 需要鉴权 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 消息 ID |

**请求参数**：无

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": null
}
```

---

### 11.4 全部标记已读

**接口描述**：将当前用户所有未读消息标记为已读。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/messages/read-all` |
| 鉴权 | 需要鉴权 |

**请求参数**：无

**响应示例**

```json
{
  "code": 200,
  "message": "全部消息已标记为已读",
  "data": {
    "affectedCount": 5
  }
}
```

---

## 12. 聊天模块（Chat）

### 12.1 聊天会话列表

**接口描述**：获取当前用户的所有聊天会话，每个会话关联一条投递记录。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/chat/sessions` |
| 鉴权 | 需要鉴权 |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| page | Integer | 否 | 页码（默认 1） |
| pageSize | Integer | 否 | 每页条数（默认 20） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "applicationId": 1,
        "taskId": 1,
        "taskTitle": "周末餐厅服务员",
        "taskStatus": 1,
        "applicationStatus": 0,
        "counterpartId": 2,
        "counterpartName": "李 HR",
        "counterpartAvatar": "https://cdn.uniseek.com/avatars/2.jpg",
        "lastMessage": "你好，请问工作时间是几点到几点？",
        "lastMessageTime": "2026-07-13 11:30:00",
        "unreadCount": 2
      }
    ],
    "total": 3,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  }
}
```

| 响应字段 | 类型 | 说明 |
|---|---|---|
| applicationId | Long | 投递记录 ID（即会话标识） |
| taskId | Long | 关联职位 ID |
| taskTitle | String | 关联职位标题 |
| taskStatus | Integer | 职位状态 |
| applicationStatus | Integer | 投递状态（0~5），详见 14.1 |
| counterpartId | Long | 对方用户 ID |
| counterpartName | String | 对方昵称 |
| counterpartAvatar | String | 对方头像 URL |
| lastMessage | String | 最后一条消息摘要 |
| lastMessageTime | String | 最后一条消息时间 |
| unreadCount | Integer | 未读消息数（用于高亮标记） |

**列表排序**：按 `lastMessageTime` 倒序排列，未读会话（`unreadCount > 0`）前端需加粗/高亮标记。

---

### 12.2 加载聊天历史消息

**接口描述**：加载指定会话的聊天历史消息，按时间正序排列，自动将对方消息标记为已读。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/chat/sessions/{applicationId}/messages` |
| 鉴权 | 需要鉴权 |
| 权限 | 求职者：仅限自己的投递；HR：仅限本企业职位的投递；管理员：全部 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| applicationId | Long | 投递记录 ID |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| beforeId | Long | 否 | 加载此 ID 之前的消息（向上翻页），不传则加载最新 20 条 |
| pageSize | Integer | 否 | 每页条数（默认 20，最大 50） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "senderId": 1,
        "senderName": "张三",
        "senderAvatar": "https://cdn.uniseek.com/avatars/1.jpg",
        "messageType": 0,
        "content": "您好，我对这个职位很感兴趣",
        "isRead": 1,
        "createTime": "2026-07-13 10:05:00"
      },
      {
        "id": 2,
        "senderId": 2,
        "senderName": "李 HR",
        "senderAvatar": "https://cdn.uniseek.com/avatars/2.jpg",
        "messageType": 0,
        "content": "你好，请问你的工作经验是？",
        "isRead": 1,
        "createTime": "2026-07-13 10:10:00"
      }
    ],
    "hasMore": false
  }
}
```

---

### 12.3 发送聊天消息

**接口描述**：在指定会话中发送聊天消息。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/chat/sessions/{applicationId}/messages` |
| 鉴权 | 需要鉴权 |
| 权限 | 求职者：仅限自己的投递；HR：仅限本企业职位的投递 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| applicationId | Long | 投递记录 ID |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| messageType | Integer | 否 | 消息类型：0 文本（默认）/ 1 图片 |
| content | String | 是 | 消息内容（1~2000 字），图片类型时传图片 URL |

**请求示例（文本消息）**

```json
{
  "messageType": 0,
  "content": "你好，请问工作时间是几点到几点？"
}
```

**请求示例（图片消息）**

```json
{
  "messageType": 1,
  "content": "https://cdn.uniseek.com/chat/images/20260713/abc123.jpg"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "发送成功",
  "data": {
    "id": 3,
    "senderId": 1,
    "messageType": 0,
    "content": "你好，请问工作时间是几点到几点？",
    "isRead": 0,
    "createTime": "2026-07-13 11:30:00"
  }
}
```

**异常响应**

| 场景 | 响应 |
|---|---|
| 权限校验失败 | `{ "code": 403, "message": "无权发送消息" }` |
| 消息内容为空 | `{ "code": 400, "message": "消息内容不能为空" }` |
| 消息内容超长 | `{ "code": 400, "message": "消息内容不能超过 2000 字" }` |

---

### 12.4 获取会话详情

**接口描述**：获取指定聊天会话的详细信息，包括关联的职位信息、投递状态、对方信息等。用于聊天页面顶部信息栏展示及快捷操作入口。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/chat/sessions/{applicationId}` |
| 鉴权 | 需要鉴权 |
| 权限 | 求职者：仅限自己的投递；HR：仅限本企业职位的投递；管理员：全部 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| applicationId | Long | 投递记录 ID（即会话标识） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "applicationId": 1,
    "applicationStatus": 1,
    "taskId": 1,
    "taskTitle": "周末餐厅服务员",
    "taskStatus": 1,
    "enterpriseName": "某某餐饮有限公司",
    "counterpartId": 2,
    "counterpartName": "李 HR",
    "counterpartAvatar": "https://cdn.uniseek.com/avatars/2.jpg",
    "applicantId": 1,
    "applicantName": "张三",
    "applicantAvatar": "https://cdn.uniseek.com/avatars/1.jpg",
    "createTime": "2026-07-13 10:00:00"
  }
}
```

| 响应字段 | 类型 | 说明 |
|---|---|---|
| applicationId | Long | 投递记录 ID |
| applicationStatus | Integer | 投递状态（0~5），详见 14.1 |
| taskId | Long | 关联职位 ID（可点击跳转职位详情） |
| taskTitle | String | 关联职位标题 |
| taskStatus | Integer | 职位状态 |
| enterpriseName | String | 企业名称 |
| counterpartId | Long | 对方用户 ID |
| counterpartName | String | 对方昵称 |
| counterpartAvatar | String | 对方头像 URL |
| applicantId | Long | 求职者用户 ID |
| applicantName | String | 求职者昵称 |
| applicantAvatar | String | 求职者头像 URL |
| createTime | String | 会话创建时间 |

**快捷操作说明**：HR 端在聊天页面可根据当前 `applicationStatus` 展示快捷操作按钮（调用 8.5 修改投递状态接口）：

| 当前投递状态 | 可用的快捷操作 |
|---|---|
| 0（已投递） | 标记面试、待定、淘汰 |
| 1（待面试） | 标记录用、待定、淘汰 |
| 2（待定） | 标记面试、标记录用、淘汰 |
| 3（已录用） | 结算确认（调用 8.6） |

---

### 12.5 标记会话已读

**接口描述**：将指定会话中所有对方发送的未读消息标记为已读。接收方进入聊天页面时调用，作为 WebSocket 已读回执的 HTTP 补充方案。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/chat/sessions/{applicationId}/read` |
| 鉴权 | 需要鉴权 |
| 权限 | 求职者：仅限自己的投递；HR：仅限本企业职位的投递 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| applicationId | Long | 投递记录 ID |

**请求参数**：无

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "affectedCount": 3
  }
}
```

**说明**：标记已读后，发送方可通过 WebSocket `MESSAGE_READ` 事件或下次轮询时感知消息已读状态变更。

---

### 12.6 WebSocket 实时推送

**概述**：聊天模块采用 WebSocket 协议实现实时消息推送。客户端与服务端建立长连接后，无需轮询即可实时接收新消息、消息已读状态变更等事件。

#### 12.6.1 连接建立

| 项目 | 内容 |
|---|---|
| 协议 | WebSocket（`ws://` 或 `wss://`） |
| 连接地址 | `ws://{host}:{port}/ws/chat` |
| 鉴权方式 | 连接时在 URL 参数中携带 JWT Token：`ws://{host}:{port}/ws/chat?token={jwt_token}` |
| 心跳机制 | 客户端每 30 秒发送 Ping 帧，服务端回复 Pong 帧；若 90 秒内未收到心跳，服务端主动断开连接 |

**连接流程**：
1. 客户端携带 JWT Token 发起 WebSocket 握手请求
2. 服务端验证 Token 有效性，解析用户身份
3. 握手成功后，服务端将连接与用户 ID 绑定，存入连接池
4. 同一用户可在多个设备建立连接，消息会广播到该用户的所有连接

#### 12.6.2 消息推送格式

所有 WebSocket 消息使用统一的 JSON 帧格式：

```json
{
  "type": "MESSAGE_TYPE",
  "data": {},
  "timestamp": "2026-07-13 11:30:00"
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| type | String | 消息类型（见下方枚举） |
| data | Object | 消息载荷，不同类型结构不同 |
| timestamp | String | 服务端推送时间 |

#### 12.6.3 消息类型枚举（WebSocket 推送事件）

| type 值 | 说明 | data 载荷 |
|---|---|---|
| `NEW_MESSAGE` | 新聊天消息 | `{ "messageId": 1, "applicationId": 1, "senderId": 2, "senderName": "李HR", "senderAvatar": "https://...", "content": "你好", "messageType": 0, "sendTime": "2026-07-13 11:30:00" }` |
| `MESSAGE_READ` | 消息已读回执 | `{ "applicationId": 1, "readerId": 1, "lastReadMessageId": 5 }` |
| `SESSION_UPDATE` | 会话列表更新 | `{ "applicationId": 1, "lastMessage": "你好", "lastMessageTime": "2026-07-13 11:30:00", "unreadCount": 2 }` |
| `NOTIFICATION` | 系统通知（面试邀请/录用/淘汰等） | `{ "messageId": 1, "title": "面试邀请", "content": "...", "type": 1, "senderId": 2, "senderName": "李HR" }` |
| `ERROR` | 错误通知 | `{ "code": 400, "message": "消息内容不能为空" }` |

#### 12.6.4 客户端发送消息

客户端可通过 WebSocket 直接发送聊天消息，无需通过 HTTP 接口：

**发送格式**：

```json
{
  "type": "SEND_MESSAGE",
  "data": {
    "applicationId": 1,
    "messageType": 0,
    "content": "你好，请问工作时间是几点？"
  }
}
```

**说明**：
- `messageType`: 0 文本，1 图片（图片内容传 URL）
- 内容长度限制：1~2000 字

**服务端响应（成功）**：

```json
{
  "type": "SEND_ACK",
  "data": {
    "messageId": 3,
    "applicationId": 1,
    "messageType": 0,
    "content": "你好，请问工作时间是几点？",
    "sendTime": "2026-07-13 11:30:00"
  },
  "timestamp": "2026-07-13 11:30:00"
}
```

**服务端响应（失败）**：

```json
{
  "type": "ERROR",
  "data": {
    "code": 400,
    "message": "消息内容不能为空"
  },
  "timestamp": "2026-07-13 11:30:00"
}
```

#### 12.6.5 已读回执

接收方进入聊天页面时，客户端通过 WebSocket 发送已读回执：

```json
{
  "type": "READ_RECEIPT",
  "data": {
    "applicationId": 1,
    "lastReadMessageId": 5
  }
}
```

服务端收到后将该会话中 `messageId ≤ 5` 且 `sender_id ≠ 当前用户` 的消息标记为已读，并向发送方推送 `MESSAGE_READ` 事件。

#### 12.6.6 断线重连

| 策略 | 说明 |
|---|---|
| 重连间隔 | 首次 1 秒，指数退避，最大 30 秒 |
| 重连次数 | 最多重连 5 次 |
| 重连后操作 | 重新加载最近会话列表，补拉断线期间的消息 |

---

## 13. 文件上传模块（Upload）

### 13.1 上传图片

**接口描述**：上传图片文件，用于营业执照、头像等。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/upload/image` |
| 鉴权 | 需要鉴权 |
| Content-Type | `multipart/form-data` |

**请求参数（Form-Data）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| file | File | 是 | 图片文件，支持 jpg / png / webp，最大 5MB |

**响应示例**

```json
{
  "code": 200,
  "message": "上传成功",
  "data": {
    "url": "https://cdn.uniseek.com/images/20260713/abc123.jpg"
  }
}
```

---

### 13.2 上传文件

**接口描述**：上传通用文件，用于附件简历等。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/upload/file` |
| 鉴权 | 需要鉴权 |
| Content-Type | `multipart/form-data` |

**请求参数（Form-Data）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| file | File | 是 | 文件，支持 pdf / doc / docx，最大 10MB |

**响应示例**

```json
{
  "code": 200,
  "message": "上传成功",
  "data": {
    "url": "https://cdn.uniseek.com/files/20260713/xyz789.pdf"
  }
}
```

---

## 14. 投诉处理模块（Complaint）

> 用户可以举报违规职位、虚假企业或不良用户行为，运营管理员受理并处理投诉。

### 14.1 提交投诉

**接口描述**：用户提交投诉举报。

| 项目 | 内容 |
|---|---|
| 请求路径 | `POST /api/complaints` |
| 鉴权 | 需要鉴权 |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| targetType | Integer | 是 | 被投诉对象类型：0 职位 / 1 企业 / 2 用户 |
| targetId | Long | 是 | 被投诉对象 ID |
| type | Integer | 是 | 投诉类型 |
| content | String | 是 | 投诉内容（1~500 字） |

**请求示例**

```json
{
  "targetType": 0,
  "targetId": 1,
  "type": 0,
  "content": "该职位描述与实际工作内容严重不符，存在虚假宣传"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "投诉提交成功",
  "data": {
    "id": 1,
    "status": 0,
    "createTime": "2026-07-13 15:00:00"
  }
}
```

---

### 14.2 投诉列表（管理员）

**接口描述**：管理员查看所有投诉记录。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/admin/complaints` |
| 鉴权 | 需要鉴权，角色限制：管理员（9） |
| 权限 | 管理员 |

**请求参数（Query）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| status | Integer | 否 | 处理状态：0 待处理 / 1 处理中 / 2 已结案 |
| targetType | Integer | 否 | 被投诉对象类型：0 职位 / 1 企业 / 2 用户 |
| page | Integer | 否 | 页码（默认 1） |
| pageSize | Integer | 否 | 每页条数（默认 20） |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "complainantId": 1,
        "complainantName": "张三",
        "targetType": 0,
        "targetId": 1,
        "targetName": "周末餐厅服务员",
        "type": 0,
        "content": "该职位描述与实际工作内容严重不符",
        "status": 0,
        "handlerId": null,
        "handlerName": null,
        "handleResult": null,
        "createTime": "2026-07-13 15:00:00",
        "updateTime": "2026-07-13 15:00:00"
      }
    ],
    "total": 5,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  }
}
```

---

### 14.3 投诉详情

**接口描述**：管理员查看投诉详情。

| 项目 | 内容 |
|---|---|
| 请求路径 | `GET /api/admin/complaints/{id}` |
| 鉴权 | 需要鉴权，角色限制：管理员（9） |
| 权限 | 管理员 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 投诉 ID |

**响应示例**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1,
    "complainantId": 1,
    "complainantName": "张三",
    "complainantPhone": "138****8000",
    "targetType": 0,
    "targetId": 1,
    "targetName": "周末餐厅服务员",
    "targetDetail": {
      "taskId": 1,
      "taskTitle": "周末餐厅服务员",
      "enterpriseName": "某某餐饮有限公司",
      "status": 1
    },
    "type": 0,
    "content": "该职位描述与实际工作内容严重不符，存在虚假宣传",
    "status": 0,
    "handlerId": null,
    "handlerName": null,
    "handleResult": null,
    "createTime": "2026-07-13 15:00:00",
    "updateTime": "2026-07-13 15:00:00"
  }
}
```

---

### 14.4 处理投诉（管理员）

**接口描述**：管理员受理投诉，填写处理结果并结案。

| 项目 | 内容 |
|---|---|
| 请求路径 | `PUT /api/admin/complaints/{id}/handle` |
| 鉴权 | 需要鉴权，角色限制：管理员（9） |
| 权限 | 管理员 |

**路径参数**

| 参数名 | 类型 | 说明 |
|---|---|---|
| id | Long | 投诉 ID |

**请求参数（Body）**

| 参数名 | 类型 | 必填 | 说明 |
|---|---|---|---|
| status | Integer | 是 | 处理状态：1 处理中 / 2 已结案 |
| handleResult | String | 条件必填 | 处理结果，结案时必填 |

**请求示例（结案）**

```json
{
  "status": 2,
  "handleResult": "经核实，该职位描述确实存在夸大宣传，已下架该职位并通知企业修改"
}
```

**响应示例**

```json
{
  "code": 200,
  "message": "处理完成",
  "data": {
    "id": 1,
    "status": 2,
    "handlerId": 9,
    "handlerName": "管理员",
    "handleResult": "经核实，该职位描述确实存在夸大宣传，已下架该职位并通知企业修改",
    "updateTime": "2026-07-13 16:00:00"
  }
}
```

---

## 15. API 接口汇总

| 序号 | 模块 | 方法 | 路径 | 权限 | 说明 |
|---|---|---|---|---|---|
| 1 | 认证 | POST | `/api/auth/register` | 公开 | 用户注册（手机号+邮箱+密码） |
| 2 | 认证 | POST | `/api/auth/login` | 公开 | 用户登录 |
| 3 | 认证 | POST | `/api/auth/logout` | 登录 | 退出登录 |
| 4 | 认证 | GET | `/api/auth/current-user` | 登录 | 获取当前用户信息 |
| 5 | 认证 | PUT | `/api/auth/password` | 登录 | 修改密码 |
| 6 | 认证 | POST | `/api/auth/real-name` | 登录 | 实名认证 |
| 7 | 认证 | GET | `/api/auth/real-name/status` | 登录 | 获取实名认证状态 |
| 8 | 用户 | PUT | `/api/user/profile` | 登录 | 更新个人资料 |
| 9 | 简历 | GET | `/api/resume` | 求职者 | 获取我的简历 |
| 10 | 简历 | PUT | `/api/resume` | 求职者 | 创建/更新简历 |
| 11 | 简历 | POST | `/api/resume/upload-attachment` | 求职者 | 上传附件简历 |
| 12 | 分类 | GET | `/api/categories` | 登录 | 获取分类列表 |
| 13 | 地区 | GET | `/api/region/provinces` | 公开 | 获取所有省级行政区划 |
| 14 | 地区 | GET | `/api/region/children/{parentId}` | 公开 | 获取子级行政区划 |
| 15 | 地区 | GET | `/api/region/tree` | 公开 | 获取省/市/区三级树形结构 |
| 16 | 职位 | GET | `/api/tasks` | 登录 | 职位列表（搜索&筛选） |
| 17 | 职位 | GET | `/api/tasks/{id}` | 登录 | 职位详情 |
| 18 | 职位 | POST | `/api/tasks` | 企业 HR | 发布职位 |
| 19 | 职位 | PUT | `/api/tasks/{id}` | 企业 HR | 更新职位 |
| 20 | 职位 | PUT | `/api/tasks/{id}/status` | HR/管理员 | 修改职位状态 |
| 21 | 职位 | GET | `/api/enterprise/tasks` | 企业 HR | 本企业职位列表 |
| 22 | 投递 | POST | `/api/applications` | 求职者 | 投递职位 |
| 23 | 投递 | GET | `/api/applications/my` | 求职者 | 我的投递记录 |
| 24 | 投递 | GET | `/api/applications/{id}` | 登录 | 投递详情 |
| 25 | 投递 | GET | `/api/tasks/{taskId}/applications` | 企业 HR | 职位投递列表 |
| 26 | 投递 | PUT | `/api/applications/{id}/status` | 企业 HR | 修改投递状态 |
| 27 | 投递 | PUT | `/api/applications/{id}/complete` | 企业 HR | 结算确认（已录用→已完成） |
| 28 | 企业 | POST | `/api/enterprise` | 企业 HR | 提交企业资质 |
| 29 | 企业 | GET | `/api/enterprise/my` | 企业 HR | 获取我的企业信息 |
| 30 | 企业 | PUT | `/api/enterprise` | 企业 HR | 更新企业信息 |
| 31 | 管理 | GET | `/api/admin/enterprises` | 管理员 | 企业审核列表 |
| 32 | 管理 | PUT | `/api/admin/enterprises/{id}/audit` | 管理员 | 企业资质审核 |
| 33 | 管理 | GET | `/api/admin/tasks/pending` | 管理员 | 待审核职位列表 |
| 34 | 管理 | PUT | `/api/admin/tasks/{id}/audit` | 管理员 | 职位审核 |
| 35 | 管理 | GET | `/api/admin/statistics` | 管理员 | 数据统计看板 |
| 36 | 管理 | GET | `/api/admin/users` | 管理员 | 用户管理列表 |
| 37 | 管理 | PUT | `/api/admin/users/{id}/status` | 管理员 | 禁用/启用用户 |
| 38 | 管理 | GET | `/api/admin/operation-logs` | 管理员 | 操作审计日志 |
| 39 | 管理 | GET | `/api/admin/complaints` | 管理员 | 投诉列表 |
| 40 | 管理 | GET | `/api/admin/complaints/{id}` | 管理员 | 投诉详情 |
| 41 | 管理 | PUT | `/api/admin/complaints/{id}/handle` | 管理员 | 处理投诉 |
| 42 | 投诉 | POST | `/api/complaints` | 登录 | 提交投诉 |
| 43 | 消息 | GET | `/api/messages` | 登录 | 消息列表 |
| 44 | 消息 | GET | `/api/messages/unread-count` | 登录 | 未读消息数 |
| 45 | 消息 | PUT | `/api/messages/{id}/read` | 登录 | 标记消息已读 |
| 46 | 消息 | PUT | `/api/messages/read-all` | 登录 | 全部标记已读 |
| 47 | 聊天 | GET | `/api/chat/sessions` | 登录 | 聊天会话列表 |
| 48 | 聊天 | GET | `/api/chat/sessions/{applicationId}` | 登录 | 获取会话详情 |
| 49 | 聊天 | GET | `/api/chat/sessions/{applicationId}/messages` | 登录 | 加载聊天历史 |
| 50 | 聊天 | POST | `/api/chat/sessions/{applicationId}/messages` | 登录 | 发送聊天消息（HTTP） |
| 51 | 聊天 | PUT | `/api/chat/sessions/{applicationId}/read` | 登录 | 标记会话已读 |
| 52 | 聊天 | WS | `ws://{host}:{port}/ws/chat` | 登录 | WebSocket 实时推送 |
| 53 | 上传 | POST | `/api/upload/image` | 登录 | 上传图片 |
| 54 | 上传 | POST | `/api/upload/file` | 登录 | 上传文件 |

---

## 16. 附录：状态枚举说明

### 16.1 投递状态（Application Status）

| 状态值 | 状态名称 | 说明 |
|---|---|---|
| 0 | 已投递 | 求职者已投递简历，等待 HR 处理 |
| 1 | 待面试 | HR 已标记为待面试，已发送面试邀请 |
| 2 | 待定 | HR 暂未做最终决定 |
| 3 | 已录用 | HR 已录用该求职者 |
| 4 | 已淘汰 | HR 已淘汰该求职者 |
| 5 | 已完成 | 该兼职工作已结算完成 |

### 16.2 职位状态（Task Status）

| 状态值 | 状态名称 | 说明 |
|---|---|---|
| 0 | 待审核 | 企业已提交，等待运营审核 |
| 1 | 招聘中 | 审核通过，求职者可浏览投递 |
| 2 | 已满员 | 剩余名额为 0，自动变更 |
| 3 | 已过期 | 报名截止时间已过 |
| 4 | 已下架 | 企业手动下架或运营强制下架 |

### 16.3 企业审核状态（Audit Status）

| 状态值 | 状态名称 | 说明 |
|---|---|---|
| 0 | 待审核 | 企业已提交资质，等待审核 |
| 1 | 已认证 | 审核通过 |
| 2 | 驳回 | 审核驳回，需修改后重新提交 |

### 16.4 薪资单位（Salary Unit）

| 值 | 说明 |
|---|---|
| 0 | 日结 |
| 1 | 时薪 |
| 2 | 月结 |

### 16.5 消息类型（Message Type）

| 值 | 说明 |
|---|---|
| 0 | 系统通知 |
| 1 | 面试邀请 |
| 2 | 录用通知 |
| 3 | 淘汰通知 |
| 4 | 聊天消息 |

### 16.6 用户角色（Role）

| 值 | 说明 |
|---|---|
| 0 | 求职者 |
| 1 | 企业 HR |
| 9 | 运营管理员 |

### 16.7 用户状态（User Status）

| 值 | 说明 |
|---|---|
| 0 | 禁用 |
| 1 | 正常 |

### 16.8 聊天消息类型（Chat Message Type）

| 值 | 说明 |
|---|---|
| 0 | 文本 |
| 1 | 图片 |

### 16.9 WebSocket 事件类型（WebSocket Event Type）

| type 值 | 方向 | 说明 |
|---|---|---|
| `SEND_MESSAGE` | 客户端 → 服务端 | 发送聊天消息 |
| `SEND_ACK` | 服务端 → 客户端 | 消息发送确认 |
| `NEW_MESSAGE` | 服务端 → 客户端 | 推送新聊天消息 |
| `READ_RECEIPT` | 客户端 → 服务端 | 已读回执 |
| `MESSAGE_READ` | 服务端 → 客户端 | 消息已读通知 |
| `SESSION_UPDATE` | 服务端 → 客户端 | 会话列表更新 |
| `NOTIFICATION` | 服务端 → 客户端 | 系统通知推送 |
| `ERROR` | 服务端 → 客户端 | 错误通知 |

### 16.10 岗位类型（Job Type）

| 值 | 说明 |
|---|---|
| 1 | 全职 |
| 2 | 兼职 |
| 3 | 实习 |

### 16.11 行政区划层级（Region Level）

| 值 | 说明 |
|---|---|
| 1 | 省（直辖市/自治区） |
| 2 | 市（地级市/自治州/盟） |
| 3 | 区县（区/县级市/旗） |

### 16.12 投诉处理状态（Complaint Status）

| 值 | 说明 |
|---|---|
| 0 | 待处理 |
| 1 | 处理中 |
| 2 | 已结案 |