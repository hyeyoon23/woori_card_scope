package dev.sample.service;

import dev.sample.dto.*;
import dev.sample.dao.*;
import dev.sample.service.*;
import dev.sample.config.*;
import dev.sample.filter.*;

import javax.sql.DataSource;
import java.sql.SQLException;

public class UserService {

    private final UserDAO userDAO;

    public UserService(DataSource dataSource) {
        this.userDAO = new UserDAO(dataSource);
    }

    /**
     * 로그인 (아이디/비밀번호 검증)
     * 
     * @return 로그인 성공 시 UserDTO 반환, 실패 시 null 반환
     */
    public UserDTO login(String id, String password) {
        try {
            UserDTO user = userDAO.findById(id);
            if (user != null && user.getPassword().equals(password)) {
                return user; // 인증 성공
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null; // 인증 실패 (아이디 없음 or 비밀번호 불일치)
    }

    /**
     * 회원가입
     * 
     * @return 가입 성공 시 true, 실패 시 false
     */
    public boolean signup(String id, String password, String name) {
        try {
            UserDTO existingUser = userDAO.findById(id);
            if (existingUser != null) {
                return false; // 이미 존재하는 아이디
            }

            UserDTO newUser = UserDTO.builder()
                    .id(id)
                    .password(password)
                    .name(name)
                    .build();

            return userDAO.insertUser(newUser);
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
