package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.uniseek.entity.Resume;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 简历 Mapper
 */
@Mapper
public interface ResumeMapper extends BaseMapper<Resume> {

    /**
     * 查询简历及实名信息（LEFT JOIN real_name_auth 获取 realName）
     *
     * @param userId 用户 ID
     * @return 简历信息（含 realName 字段）
     */
    Resume selectResumeWithRealName(@Param("userId") Long userId);

    /**
     * 分页查询已发布到人才市场的简历（支持关键词搜索和筛选）
     *
     * @param page      MyBatis-Plus 分页对象
     * @param keyword   搜索关键词
     * @param kwPattern 搜索关键词正则
     * @param filter    筛选条件：全部 / 有附件简历 / 在校生 / 有工作经验
     * @return 分页结果
     */
    IPage<Resume> selectPublishedResumes(Page<Resume> page, @Param("keyword") String keyword, @Param("kwPattern") String kwPattern, @Param("filter") String filter);
}