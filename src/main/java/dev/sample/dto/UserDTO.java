package dev.sample.dto;

import dev.sample.dto.*;
import dev.sample.dao.*;
import dev.sample.service.*;
import dev.sample.config.*;
import dev.sample.filter.*;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

/**
 * 로그인 계정 정보
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDTO implements Serializable {
    private static final long serialVersionUID = 1L;

    private String id;
    private String password;
    private String name;
}
