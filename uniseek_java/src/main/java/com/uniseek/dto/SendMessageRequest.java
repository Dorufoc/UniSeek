package com.uniseek.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * 发送消息请求 DTO
 */
@Data
public class SendMessageRequest {

    /** 消息类型：0 文本 / 1 图片 / 2 简历附件（默认文本） */
    private Integer messageType = 0;

    /** 消息内容 */
    @NotBlank(message = "消息内容不能为空")
    @Size(max = 2000, message = "消息内容不能超过2000个字符")
    private String content;
}
