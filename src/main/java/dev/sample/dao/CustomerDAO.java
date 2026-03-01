package dev.sample.dao;

import dev.sample.dto.*;
import dev.sample.dao.*;
import dev.sample.service.*;
import dev.sample.config.*;
import dev.sample.filter.*;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.sql.DataSource;

public class CustomerDAO {
	private final DataSource readDataSource;

	// ──── 랭크 코드 → 랭크명 매핑 ────
	private static final Map<String, String> RANK_NAME_MAP = new LinkedHashMap<>();
	static {
		RANK_NAME_MAP.put("21", "VVIP");
		RANK_NAME_MAP.put("22", "VIP");
		RANK_NAME_MAP.put("23", "Platinum");
		RANK_NAME_MAP.put("24", "Gold");
		RANK_NAME_MAP.put("25", "기타");
	}

	// ──── 현재 랭크 기준금액 (만원) ────
	private static final Map<String, BigDecimal> CURRENT_RANK_AMOUNT = new LinkedHashMap<>();
	static {
		CURRENT_RANK_AMOUNT.put("25", BigDecimal.ZERO);
		CURRENT_RANK_AMOUNT.put("24", new BigDecimal("1000")); // Gold
		CURRENT_RANK_AMOUNT.put("23", new BigDecimal("2500")); // Platinum
		CURRENT_RANK_AMOUNT.put("22", new BigDecimal("5000")); // VIP
		CURRENT_RANK_AMOUNT.put("21", new BigDecimal("10000"));// VVIP
	}

	// ──── 다음 랭크 코드 매핑 (25→24→23→22→21) ────
	private static final Map<String, String> NEXT_RANK_MAP = new LinkedHashMap<>();
	static {
		NEXT_RANK_MAP.put("25", "24");
		NEXT_RANK_MAP.put("24", "23");
		NEXT_RANK_MAP.put("23", "22");
		NEXT_RANK_MAP.put("22", "21");
		// 21(VVIP) → 다음랭크 없음
	}

	// ──── 다음 랭크 기준금액 (만원) ────
	private static final Map<String, BigDecimal> NEXT_RANK_AMOUNT = new LinkedHashMap<>();
	static {
		NEXT_RANK_AMOUNT.put("25", new BigDecimal("1000")); // Next is Gold
		NEXT_RANK_AMOUNT.put("24", new BigDecimal("2500")); // Next is Platinum
		NEXT_RANK_AMOUNT.put("23", new BigDecimal("5000")); // Next is VIP
		NEXT_RANK_AMOUNT.put("22", new BigDecimal("10000")); // Next is VVIP
		// 21(VVIP) → 다음랭크 없음
	}

	// ──── 중분류 컬럼명 목록 (10개) ────
	private static final String[] MID_CATEGORY_COLUMNS = {
			"INTERIOR_AM", "INSUHOS_AM", "OFFEDU_AM", "TRVLEC_AM", "FSBZ_AM",
			"SVCARC_AM", "DIST_AM", "PLSANIT_AM", "CLOTHGDS_AM", "AUTO_AM"
	};

	public CustomerDAO(DataSource readDataSource) {
		if (readDataSource == null) {
			throw new IllegalArgumentException("readDataSource must not be null");
		}
		this.readDataSource = readDataSource;
	}

	// ════════════════════════════════════════════════════════════════
	// 1. findAll – 전체 목록 (SEQ별 TOT_USE_AM 합산 + Deferred Join 페이징)
	// ════════════════════════════════════════════════════════════════
	public List<CustomerDTO.ListAllDTO> findAll(int page, int pageSize) throws SQLException {
		List<CustomerDTO.ListAllDTO> list = new ArrayList<>();

		int offset = (page - 1) * pageSize;

		String sql = "SELECT SUBSTR(c.BAS_YH, 1, 4) AS BAS_YH, c.SEQ, "
				+ "MAX(c.MBR_RK) AS MBR_RK, MAX(c.AGE) AS AGE, MAX(c.SEX_CD) AS SEX_CD, "
				+ "MAX(c.HOUS_SIDO_NM) AS HOUS_SIDO_NM, SUM(c.TOT_USE_AM) AS TOT_USE_AM "
				+ "FROM CARD_TRANSACTION c "
				+ "JOIN ("
				+ "  SELECT DISTINCT SEQ FROM CARD_TRANSACTION "
				+ "  ORDER BY SEQ LIMIT ? OFFSET ?"
				+ ") tmp ON c.SEQ = tmp.SEQ "
				+ "GROUP BY SUBSTR(c.BAS_YH, 1, 4), c.SEQ "
				+ "ORDER BY c.SEQ, SUBSTR(c.BAS_YH, 1, 4)";

		try (Connection conn = readDataSource.getConnection();
				PreparedStatement pstmt = conn.prepareStatement(sql)) {

			pstmt.setInt(1, pageSize);
			pstmt.setInt(2, offset);

			try (ResultSet rs = pstmt.executeQuery()) {
				while (rs.next()) {
					CustomerDTO.ListAllDTO dto = new CustomerDTO.ListAllDTO(
							rs.getString("BAS_YH"),
							rs.getString("SEQ"),
							rs.getString("MBR_RK"),
							rs.getString("AGE"),
							rs.getString("SEX_CD"),
							rs.getString("HOUS_SIDO_NM"),
							rs.getBigDecimal("TOT_USE_AM"));
					list.add(dto);
				}
			}
		}
		return list;
	}

	// ════════════════════════════════════════════════════════════════
	// 2. findByFilter – 필터 조건 목록 (동적 쿼리 + Deferred Join 페이징)
	// ════════════════════════════════════════════════════════════════
	public List<CustomerDTO.ListAllDTO> findByFilter(String mbrRk, String age, String sexCd,
			String housSidoNm, String seq, int page, int pageSize) throws SQLException {
		List<CustomerDTO.ListAllDTO> list = new ArrayList<>();
		int offset = (page - 1) * pageSize;
		List<Object> innerParams = new ArrayList<>();

		StringBuilder innerSql = new StringBuilder(
				"SELECT DISTINCT SEQ FROM CARD_TRANSACTION WHERE 1=1");

		appendFilter(innerSql, innerParams, "MBR_RK", mbrRk);
		appendFilter(innerSql, innerParams, "AGE", age);
		appendFilter(innerSql, innerParams, "SEX_CD", sexCd);
		appendFilter(innerSql, innerParams, "HOUS_SIDO_NM", housSidoNm);
		appendFilter(innerSql, innerParams, "SEQ", seq);

		innerSql.append(" ORDER BY SEQ LIMIT ? OFFSET ?");
		innerParams.add(pageSize);
		innerParams.add(offset);

		List<Object> outerParams = new ArrayList<>();
		StringBuilder outerWhere = new StringBuilder();
		appendFilter(outerWhere, outerParams, "c.MBR_RK", mbrRk);
		appendFilter(outerWhere, outerParams, "c.AGE", age);
		appendFilter(outerWhere, outerParams, "c.SEX_CD", sexCd);
		appendFilter(outerWhere, outerParams, "c.HOUS_SIDO_NM", housSidoNm);

		String sql = "SELECT SUBSTR(c.BAS_YH, 1, 4) AS BAS_YH, c.SEQ, "
				+ "MAX(c.MBR_RK) AS MBR_RK, MAX(c.AGE) AS AGE, MAX(c.SEX_CD) AS SEX_CD, "
				+ "MAX(c.HOUS_SIDO_NM) AS HOUS_SIDO_NM, SUM(c.TOT_USE_AM) AS TOT_USE_AM "
				+ "FROM CARD_TRANSACTION c "
				+ "JOIN (" + innerSql.toString() + ") tmp ON c.SEQ = tmp.SEQ "
				+ "WHERE 1=1" + outerWhere.toString()
				+ " GROUP BY SUBSTR(c.BAS_YH, 1, 4), c.SEQ "
				+ "ORDER BY c.SEQ, SUBSTR(c.BAS_YH, 1, 4)";

		List<Object> allParams = new ArrayList<>();
		allParams.addAll(innerParams);
		allParams.addAll(outerParams);

		try (Connection conn = readDataSource.getConnection();
				PreparedStatement pstmt = conn.prepareStatement(sql)) {

			for (int i = 0; i < allParams.size(); i++) {
				pstmt.setObject(i + 1, allParams.get(i));
			}

			try (ResultSet rs = pstmt.executeQuery()) {
				while (rs.next()) {
					CustomerDTO.ListAllDTO dto = new CustomerDTO.ListAllDTO(
							rs.getString("BAS_YH"),
							rs.getString("SEQ"),
							rs.getString("MBR_RK"),
							rs.getString("AGE"),
							rs.getString("SEX_CD"),
							rs.getString("HOUS_SIDO_NM"),
							rs.getBigDecimal("TOT_USE_AM"));
					list.add(dto);
				}
			}
		}
		return list;
	}

	// ════════════════════════════════════════════════════════════════
	// 3. getTotalCount – 전체 건수 (페이징 계산용)
	// ════════════════════════════════════════════════════════════════
	public int getTotalCount(String mbrRk, String age, String sexCd,
			String housSidoNm, String seq) throws SQLException {
		List<Object> params = new ArrayList<>();

		StringBuilder sql = new StringBuilder(
				"SELECT COUNT(DISTINCT SEQ) AS cnt FROM CARD_TRANSACTION WHERE 1=1");

		appendFilter(sql, params, "MBR_RK", mbrRk);
		appendFilter(sql, params, "AGE", age);
		appendFilter(sql, params, "SEX_CD", sexCd);
		appendFilter(sql, params, "HOUS_SIDO_NM", housSidoNm);
		appendFilter(sql, params, "SEQ", seq);

		try (Connection conn = readDataSource.getConnection();
				PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {

			for (int i = 0; i < params.size(); i++) {
				pstmt.setObject(i + 1, params.get(i));
			}

			try (ResultSet rs = pstmt.executeQuery()) {
				if (rs.next()) {
					return rs.getInt("cnt");
				}
			}
		}
		return 0;
	}

	// ════════════════════════════════════════════════════════════════
	// 4. findBySeq – 상세 (랭크 정보 + 최대 지출 중분류 포함)
	// 전체 분기 합산 + 최신 분기 속성(AGE, MBR_RK 등) 사용
	// ════════════════════════════════════════════════════════════════
	public CustomerDTO.DetailDTO findBySeq(String seq) throws SQLException {

		// 1) 전체 분기 합산 쿼리 (TOT_USE_AM + 중분류)
		StringBuilder sumSql = new StringBuilder();
		sumSql.append("SELECT SEQ, SUM(TOT_USE_AM) AS TOT_USE_AM");
		for (String col : MID_CATEGORY_COLUMNS) {
			sumSql.append(", SUM(").append(col).append(") AS ").append(col);
		}
		sumSql.append(" FROM CARD_TRANSACTION WHERE SEQ = ? GROUP BY SEQ");

		// 2) 최신 분기 속성 쿼리
		String attrSql = "SELECT AGE, SEX_CD, HOUS_SIDO_NM, MBR_RK "
				+ "FROM CARD_TRANSACTION WHERE SEQ = ? "
				+ "ORDER BY BAS_YH DESC LIMIT 1";

		try (Connection conn = readDataSource.getConnection();
				PreparedStatement sumStmt = conn.prepareStatement(sumSql.toString());
				PreparedStatement attrStmt = conn.prepareStatement(attrSql)) {

			sumStmt.setObject(1, seq);
			attrStmt.setObject(1, seq);

			BigDecimal totUseAm = null;
			String spendingType = null;

			try (ResultSet rs = sumStmt.executeQuery()) {
				if (rs.next()) {
					totUseAm = rs.getBigDecimal("TOT_USE_AM");
					spendingType = findTopSpendingType(rs);
				} else {
					return null;
				}
			}

			String age = null, sexCd = null, housSidoNm = null, mbrRk = null;
			try (ResultSet rs = attrStmt.executeQuery()) {
				if (rs.next()) {
					age = rs.getString("AGE");
					sexCd = rs.getString("SEX_CD");
					housSidoNm = rs.getString("HOUS_SIDO_NM");
					mbrRk = rs.getString("MBR_RK");
				}
			}

			// 랭크 정보 계산
			String currentRankName = RANK_NAME_MAP.getOrDefault(mbrRk, "기타");
			BigDecimal currentRankAmount = CURRENT_RANK_AMOUNT.getOrDefault(mbrRk, BigDecimal.ZERO);

			String nextRankCode = NEXT_RANK_MAP.get(mbrRk);
			String nextRankName = null;
			BigDecimal nextRankAmount = null;
			BigDecimal remainingAmount = BigDecimal.ZERO;
			double progressPercent = 100.0;

			if (nextRankCode != null) {
				nextRankName = RANK_NAME_MAP.get(nextRankCode);
				nextRankAmount = NEXT_RANK_AMOUNT.get(mbrRk);

				if (nextRankAmount != null && nextRankAmount.compareTo(BigDecimal.ZERO) > 0) {
					remainingAmount = nextRankAmount.subtract(totUseAm);
					if (remainingAmount.compareTo(BigDecimal.ZERO) < 0) {
						remainingAmount = BigDecimal.ZERO;
					}

					progressPercent = totUseAm
							.multiply(new BigDecimal("100"))
							.divide(nextRankAmount, 2, RoundingMode.HALF_UP)
							.doubleValue();
					if (progressPercent > 100.0) {
						progressPercent = 100.0;
					}
				}
			}

			// 통합 진행률(totalProgressPercent) 계산 (UI Tracker용)
			// Gold(1000): 10%, Platinum(2500): 30%, VIP(5000): 50%, VVIP(10000): 70%,
			// MAX(20000+): 90%~100%
			double totalProgressPercent = 0.0;
			if (totUseAm != null) {
				double spend = totUseAm.doubleValue();
				if (spend <= 1000) {
					totalProgressPercent = (spend / 1000.0) * 10.0;
				} else if (spend <= 2500) {
					totalProgressPercent = 10.0 + ((spend - 1000.0) / 1500.0) * 20.0;
				} else if (spend <= 5000) {
					totalProgressPercent = 30.0 + ((spend - 2500.0) / 2500.0) * 20.0;
				} else if (spend <= 10000) {
					totalProgressPercent = 50.0 + ((spend - 5000.0) / 5000.0) * 20.0;
				} else {
					double extra = ((spend - 10000.0) / 10000.0) * 20.0;
					totalProgressPercent = 70.0 + extra;
					if (totalProgressPercent > 100.0) {
						totalProgressPercent = 100.0;
					}
				}
			}

			return new CustomerDTO.DetailDTO(
					seq,
					age,
					sexCd,
					housSidoNm,
					mbrRk,
					totUseAm,
					spendingType,
					currentRankName,
					currentRankAmount,
					nextRankName,
					nextRankAmount,
					remainingAmount,
					progressPercent,
					totalProgressPercent);
		}
	}

	// ──── 내부 헬퍼 ────

	/** 동적 쿼리 필터 조건 추가 */
	private void appendFilter(StringBuilder sql, List<Object> params,
			String column, String value) {
		if (value != null && !value.isEmpty()) {
			sql.append(" AND ").append(column).append(" = ?");
			params.add(value);
		}
	}

	/** 중분류 컬럼 중 SUM이 가장 큰 컬럼명 반환 */
	private String findTopSpendingType(ResultSet rs) throws SQLException {
		String topColumn = MID_CATEGORY_COLUMNS[0];
		BigDecimal maxVal = rs.getBigDecimal(MID_CATEGORY_COLUMNS[0]);
		if (maxVal == null) {
			maxVal = BigDecimal.ZERO;
		}

		for (int i = 1; i < MID_CATEGORY_COLUMNS.length; i++) {
			BigDecimal val = rs.getBigDecimal(MID_CATEGORY_COLUMNS[i]);
			if (val == null) {
				val = BigDecimal.ZERO;
			}
			if (val.compareTo(maxVal) > 0) {
				maxVal = val;
				topColumn = MID_CATEGORY_COLUMNS[i];
			}
		}
		return topColumn;
	}
}
