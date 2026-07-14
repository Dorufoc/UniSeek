package com.uniseek.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;

/**
 * 企业资质认证请求 DTO
 */
@Data
public class EnterpriseRequest {

    /** 企业名称 */
    @NotBlank(message = "企业名称不能为空")
    private String companyName;

    /** 统一社会信用代码 */
    @NotBlank(message = "统一社会信用代码不能为空")
    private String creditCode;

    /** 营业执照图片 URL */
    private String licenseImgUrl;

    /** 所属行业 */
    @NotBlank(message = "所属行业不能为空")
    private String industry;

    /** 企业所在地区ID */
    private Long regionId;

    /** 企业描述 */
    private String description;
}
