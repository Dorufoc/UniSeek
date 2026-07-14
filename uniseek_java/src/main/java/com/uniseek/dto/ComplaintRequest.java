package com.uniseek.dto;

import javax.validation.constraints.Max;
import javax.validation.constraints.Min;

/**
 * 提交投诉请求 DTO
 */
public class ComplaintRequest {

    /** 被投诉对象类型：1 企业 / 2 用户 */
    @Min(1)
    @Max(2)
    private Integer targetType;

    /** 被投诉对象 ID */
    private Long targetId;

    /** 投诉类型 */
    private Integer type;

    /** 投诉内容（1~500 字） */
    private String content;

    public Integer getTargetType() {
        return targetType;
    }

    public void setTargetType(Integer targetType) {
        this.targetType = targetType;
    }

    public Long getTargetId() {
        return targetId;
    }

    public void setTargetId(Long targetId) {
        this.targetId = targetId;
    }

    public Integer getType() {
        return type;
    }

    public void setType(Integer type) {
        this.type = type;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }
}
