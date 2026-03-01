package dev.sample.dao;

import dev.sample.dto.*;
import dev.sample.dao.*;
import dev.sample.service.*;
import dev.sample.config.*;
import dev.sample.filter.*;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class UserDAO {

    private final DataSource dataSource;

    public UserDAO(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    /**
     * 아이디로 유저 조회 (로그인 시 사용)
     */
    public UserDTO findById(String id) throws SQLException {
        String sql = "SELECT ID, PASSWORD, NAME FROM USERS WHERE ID = ?";

        try (Connection conn = dataSource.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, id);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return UserDTO.builder()
                            .id(rs.getString("ID"))
                            .password(rs.getString("PASSWORD"))
                            .name(rs.getString("NAME"))
                            .build();
                }
            }
        }
        return null;
    }

    /**
     * 신규 유저 등록 (회원가입 시 사용)
     */
    public boolean insertUser(UserDTO user) throws SQLException {
        String sql = "INSERT INTO USERS (ID, PASSWORD, NAME) VALUES (?, ?, ?)";

        try (Connection conn = dataSource.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, user.getId());
            pstmt.setString(2, user.getPassword());
            pstmt.setString(3, user.getName());

            int affectedRows = pstmt.executeUpdate();
            return affectedRows > 0;
        }
    }
}
