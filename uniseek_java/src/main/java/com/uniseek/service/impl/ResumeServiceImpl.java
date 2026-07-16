package com.uniseek.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.uniseek.common.PageResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.RealNameAuthMapper;
import com.uniseek.dao.ResumeMapper;
import com.uniseek.dto.ResumeRequest;
import com.uniseek.entity.RealNameAuth;
import com.uniseek.entity.Resume;
import com.uniseek.service.ResumeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 简历服务实现
 */
@Service
public class ResumeServiceImpl implements ResumeService {

    @Autowired
    private ResumeMapper resumeMapper;

    @Autowired
    private RealNameAuthMapper realNameAuthMapper;

    @Override
    public Resume getUserResume(Long userId) {
        // LEFT JOIN real_name_auth 获取 realName
        return resumeMapper.selectResumeWithRealName(userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveOrUpdateResume(Long userId, ResumeRequest request) {
        // 查询当前用户是否已有简历
        Resume existing = resumeMapper.selectOne(
                new LambdaQueryWrapper<Resume>()
                        .eq(Resume::getUserId, userId));

        Resume resume = new Resume();
        resume.setUserId(userId);
        resume.setGender(request.getGender());
        resume.setBirthDate(request.getBirthDate());
        resume.setEducation(request.getEducation());
        resume.setSchool(request.getSchool());
        resume.setSkills(request.getSkills());
        resume.setExperience(request.getExperience());
        resume.setAttachmentUrl(request.getAttachmentUrl());

        if (existing != null) {
            // 更新已有简历
            resume.setId(existing.getId());
            resume.setCreateTime(existing.getCreateTime());
            resume.setUpdateTime(LocalDateTime.now());
            resumeMapper.updateById(resume);
        } else {
            // 创建新简历
            resume.setCreateTime(LocalDateTime.now());
            resume.setUpdateTime(LocalDateTime.now());
            resumeMapper.insert(resume);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void publishResume(Long userId) {
        // 校验实名认证
        RealNameAuth auth = realNameAuthMapper.selectOne(
                new LambdaQueryWrapper<RealNameAuth>()
                        .eq(RealNameAuth::getUserId, userId)
                        .eq(RealNameAuth::getStatus, 1));
        if (auth == null) {
            throw new BusinessException("请先完成实名认证后再发布简历到人才市场");
        }
        Resume existing = resumeMapper.selectOne(
                new LambdaQueryWrapper<Resume>()
                        .eq(Resume::getUserId, userId));
        if (existing == null) {
            throw new BusinessException("请先创建简历");
        }
        existing.setIsPublished(1);
        existing.setUpdateTime(LocalDateTime.now());
        resumeMapper.updateById(existing);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void unpublishResume(Long userId) {
        Resume existing = resumeMapper.selectOne(
                new LambdaQueryWrapper<Resume>()
                        .eq(Resume::getUserId, userId));
        if (existing == null) {
            throw new BusinessException("请先创建简历");
        }
        existing.setIsPublished(0);
        existing.setUpdateTime(LocalDateTime.now());
        resumeMapper.updateById(existing);
    }

    @Override
    public PageResult<Resume> searchPublishedResumes(String keyword, int page, int pageSize) {
        String kwPattern = null;
        if (keyword != null && !keyword.trim().isEmpty()) {
            String[] tokens = keyword.trim().split("\\s+");
            StringBuilder sb = new StringBuilder();
            for (String token : tokens) {
                if (sb.length() > 0) sb.append(".*");
                for (int i = 0; i < token.length(); i++) {
                    if (i > 0) sb.append(".*");
                    String ch = String.valueOf(token.charAt(i));
                    sb.append(ch.replaceAll("([.+*?^${}()|\\[\\]\\\\])", "\\\\$1"));
                }
            }
            kwPattern = sb.toString();
        }
        Page<Resume> pg = new Page<>(page, pageSize);
        IPage<Resume> result = resumeMapper.selectPublishedResumes(pg, keyword, kwPattern);
        return PageResult.of(result);
    }
}