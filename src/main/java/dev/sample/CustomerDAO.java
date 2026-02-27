package com.example.customer;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CustomerDAO {

    private final String url = "jdbc:mysql://localhost:6446/mysql-router";
    private final String user = "root";
    private final String password = "1234";

    public CustomerDAO() {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }
    }

    private Connection getConnection() throws SQLException {
        return DriverManager.getConnection(url, user, password);
    }

    public List<CustomerDTO> findAll() {
        List<CustomerDTO> list = new ArrayList<>();
        String sql = "SELECT id, name, email FROM customer";

        try (Connection conn = getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            while (rs.next()) {
                CustomerDTO dto = new CustomerDTO(
                        rs.getLong("id"),
                        rs.getString("name"),
                        rs.getString("email")
                );
                list.add(dto);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        }

        return list;
    }

}