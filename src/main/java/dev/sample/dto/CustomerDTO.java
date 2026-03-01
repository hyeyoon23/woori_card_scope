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

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerDTO {

	// 기본 정보
	private String seq; // CHAR(12)
	private String age; // CHAR(2)
	private String sexCd; // CHAR(2)
	private String mbrRk; // CHAR(2)
	private String housSidoNm; // CHAR(40)

	// 금액 정보
	private BigDecimal totUseAm;
	private BigDecimal crdslUseAm;
	private BigDecimal cnfUseAm;
	private BigDecimal interiorAm;
	private BigDecimal insuhosAm;
	private BigDecimal offeduAm;
	private BigDecimal trvlecAm;
	private BigDecimal fsbzAm;
	private BigDecimal svcarcAm;
	private BigDecimal distAm;
	private BigDecimal plsanitAm;
	private BigDecimal clothgdsAm;
	private BigDecimal autoAm;

	// ──── 목록 조회용 DTO ────
	public record ListAllDTO(
			String basYh,
			String seq,
			String mbrRk,
			String age,
			String sexCd,
			String housSidoNm,
			BigDecimal totUseAm) {
	}

	// ──── 상세 조회용 DTO ────
	public record DetailDTO(
			String seq,
			String age,
			String sexCd,
			String housSidoNm,
			String mbrRk,
			BigDecimal totUseAm,
			String spendingType,
			String currentRankName,
			BigDecimal currentRankAmount,
			String nextRankName,
			BigDecimal nextRankAmount,
			BigDecimal remainingAmount,
			double progressPercent,
			double totalProgressPercent) {
	}
}