package dev.sample;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import javax.sql.DataSource;

public class CustomerDAO {
	private final DataSource readDataSource;

	public CustomerDAO(DataSource readDataSource) {
		if (readDataSource == null) {
			throw new IllegalArgumentException("readDataSource must not be null");
		}
		this.readDataSource = readDataSource;
	}

	public List<CustomerDTO> findAll() throws SQLException {
		List<CustomerDTO> list = new ArrayList<>();
		String sql = "SELECT seq, mbr_rk, age, sex_cd, hous_sido_nm, tot_use_am FROM customer";
		try (Connection conn = readDataSource.getConnection();
				PreparedStatement pstmt = conn.prepareStatement(sql);
				ResultSet rs = pstmt.executeQuery()) {
			while (rs.next()) {
				CustomerDTO dto = CustomerDTO.builder().seq(rs.getString("seq")).mbrRk(rs.getString("mbr_rk"))
						.age(rs.getString("age")).sexCd(rs.getString("sex_cd")).housSidoNm(rs.getString("hous_sido_nm"))
						.totUseAm(rs.getBigDecimal("tot_use_am")).build();
				list.add(dto);
			}
		}
		return list;
	}
}
