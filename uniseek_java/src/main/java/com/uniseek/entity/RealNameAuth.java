package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 实名认证实体
 */
@Data
@TableName("real_name_auth")
public class RealNameAuth {

    /** 认证记录 ID */
    @TableId
    private Long id;

    /** 用户 ID */
    private Long userId;

    /** 真实姓名 */
    private String realName;

    /** 身份证号 */
    private String idCard;

    /** 认证状态：0 未认证 / 1 已认证，默认 0 */
    private Integer status;

    /** 认证时间 */
    private LocalDateTime authTime;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
