import UIKit
import Vision
import ImageIO

struct DongThiDuaNhanVienQuet: Hashable {
    var maNV: String
    var hoTen: String
    var thucHien: Double
    var target: Double
}

struct KetQuaThiDuaNhanVienKhoi: Hashable {
    var tenNganhHang: String
    var danhSach: [DongThiDuaNhanVienQuet]
}

struct KetQuaQuetThiDua {
    var danhSach: [DongThiDua]
    var thiDuaNhanVien: [KetQuaThiDuaNhanVienKhoi]
    var doanhThuQuetDuoc: ThongTinDoanhThu?
    var capNhatLuc: String
    var thongTinDonVi: String
}

struct KetQuaQuetTatCaAnh {
    var doanhThu: ThongTinDoanhThu?
    var soAnhDoanhThu: Int = 0

    var danhSachThiDua: [DongThiDua] = []
    var soAnhThiDua: Int = 0

    var doanhThuNhanVien: [DoanhThuNhanVienItem] = []
    var soAnhDoanhThuNV: Int = 0

    var thiDuaNhanVien: [KetQuaThiDuaNhanVienKhoi] = []
    var soAnhThiDuaNV: Int = 0

    var capNhatLuc: String = ""
    var thongTinDonVi: String = ""

    var coDuLieu: Bool {
        (doanhThu?.coDuLieu ?? false) ||
        !danhSachThiDua.isEmpty ||
        !doanhThuNhanVien.isEmpty ||
        !thiDuaNhanVien.isEmpty
    }
}

final class DichVuDocAnh {
    static let dungChung = DichVuDocAnh()
    private init() {}

    private struct PhanTuVanBan {
        let chu: String
        let x: CGFloat      // 0 (trái) -> 1 (phải)
        let y: CGFloat      // 0 (đỉnh) -> 1 (đáy)
        let rong: CGFloat
        let cao: CGFloat
    }

    // MARK: - Nhận diện chính xác Ảnh chụp màn hình Doanh thu Siêu thị (tránh nhầm sang bảng Thi đua)

    /// Kiểm tra xem bức ảnh có phải là màn hình Tổng quan Doanh thu (chứa các thẻ: DT thực, DT quy đổi, % HT target, TT vs TB 3 tháng, TLPVTC, Tỷ trọng trả chậm, Chi phí) hay không.
    private func laAnhDoanhThuSieuThi(phanTu: [PhanTuVanBan]) -> Bool {
        var coDauHieuDoanhThu = 0
        for pt in phanTu where pt.y > 0.30 && pt.y < 0.96 {
            let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
            if u == "DT THUC" || u == "DT QUY DOI" || u.contains("DT QUY DOI KHOAN VAY") ||
               u.contains("TLPVTC") || u.contains("TY TRONG TRA CHAM") ||
               u.contains("TT VS TB 3 THANG") || u.contains("TB3T CUNG CUA SO") ||
               u == "CHI PHI" || u.contains("HT TARGET") ||
               u.contains("QUY THOI GIAN") || u.contains("THOI GIAN LAM VIEC") ||
               u.contains("TARGET TRON KY") || u.contains("DT TRA GOP") {
                coDauHieuDoanhThu += 1
            }
        }
        return coDauHieuDoanhThu >= 2
    }

    private func laTenTheDoanhThuKhongPhaiThiDua(_ ten: String) -> Bool {
        let u = boDau(ten)
        let cacCumCam = [
            "DT THUC", "DT QUY DOI", "DT DU KIEN", "HT TARGET",
            "TT VS TB", "TB 3 THANG", "TLPVTC", "TY TRONG TRA CHAM",
            "CHI PHI", "QUY THOI GIAN", "THOI GIAN LAM VIEC",
            "TOAN CONG TY", "SIEU THI 76", "XUAT EXCEL", "XUAT THEO MAU"
        ]
        for cum in cacCumCam {
            if u.contains(cum) { return true }
        }
        return false
    }

    // MARK: - 0. Quét & Tự động phân loại TẤT CẢ các ảnh chọn cùng lúc theo Tab đang đứng (Lũy kế hoặc Realtime)

    func quetVaPhanLoaiTatCaAnh(
        danhSachAnh: [UIImage],
        ngay: Date,
        cheDoDangChon: LoaiCheDoDoanhThu,
        tienTrinh: @escaping (String) -> Void,
        hoanTat: @escaping (KetQuaQuetTatCaAnh) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var kq = KetQuaQuetTatCaAnh()
            let laRealtime = (cheDoDangChon == .realtime)
            var dtGop = ThongTinDoanhThu()
            var cacPhanTuThiDuaDuPhong: [([PhanTuVanBan], String?)] = []

            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh("Đang đọc & phân loại ảnh \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                guard !phanTu.isEmpty else { continue }

                let (cn, dv, wm) = self.trichThongTinChungThiDua(phanTu: phanTu)
                if kq.capNhatLuc.isEmpty, let cn = cn, !cn.isEmpty {
                    kq.capNhatLuc = cn
                }
                if kq.thongTinDonVi.isEmpty, let dv = dv, !dv.isEmpty {
                    kq.thongTinDonVi = dv
                }

                // ƯU TIÊN 1: Kiểm tra xem có phải ảnh Doanh thu Siêu thị (DT thực / DT quy đổi) không
                // Phải kiểm tra ĐẦU TIÊN để không bao giờ bị nhầm sang bảng Thi đua!
                if self.laAnhDoanhThuSieuThi(phanTu: phanTu) {
                    let dt = self.phanTichDoanhThu(phanTu: phanTu)
                    if dt.coDuLieu {
                        dtGop = dtGop.gop(voi: dt, laRealtime: laRealtime)
                        kq.soAnhDoanhThu += 1
                        continue
                    }
                }

                // ƯU TIÊN 2: Kiểm tra ảnh Bảng Thực hiện Nhân viên theo Ngành hàng
                let coCotHangTrongST = phanTu.contains { pt in
                    let u = self.boDau(pt.chu)
                    return pt.y < 0.24 && (
                        u.contains("HANG TRONG") ||
                        u.contains("TOP/BOTT") ||
                        u.contains("CON / VUOT")
                    )
                }
                if coCotHangTrongST,
                   let khoiNV = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, tenNganhGoiY: nil, watermark: wm),
                   !khoiNV.danhSach.isEmpty {
                    kq.thiDuaNhanVien.append(khoiNV)
                    kq.soAnhThiDuaNV += 1
                    continue
                }

                // ƯU TIÊN 3: Kiểm tra ảnh Bảng Doanh thu hợp nhất theo Nhân viên
                let dsDTNV = self.phanTichDoanhThuNhanVienOffline(phanTu: phanTu)
                if dsDTNV.count >= 2 {
                    kq.doanhThuNhanVien.append(contentsOf: dsDTNV)
                    kq.soAnhDoanhThuNV += 1
                    continue
                }

                // ƯU TIÊN 4: Kiểm tra ảnh Lưới Thẻ Thi Đua 2 Cột
                let dsLuoiThe = self.phanTichThiDuaLuoiThe2Cot(phanTu: phanTu, watermark: wm)
                if !dsLuoiThe.isEmpty {
                    kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: kq.danhSachThiDua, moi: dsLuoiThe)
                    kq.soAnhThiDua += 1
                    continue
                }

                // ƯU TIÊN 5: Dự phòng bảng Thi đua 2 cột / 5 cột hoặc bảng NV
                if !dsDTNV.isEmpty {
                    kq.doanhThuNhanVien.append(contentsOf: dsDTNV)
                    kq.soAnhDoanhThuNV += 1
                    continue
                }
                if let khoiNV = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, tenNganhGoiY: nil, watermark: wm),
                   khoiNV.danhSach.count >= 2 {
                    kq.thiDuaNhanVien.append(khoiNV)
                    kq.soAnhThiDuaNV += 1
                    continue
                }

                cacPhanTuThiDuaDuPhong.append((phanTu, wm))
                kq.soAnhThiDua += 1
            }

            if !cacPhanTuThiDuaDuPhong.isEmpty {
                let ds = self.xuLyNhomBangThiDuaDuPhong(cacPhanTuThiDuaDuPhong)
                kq.danhSachThiDua = KhoDuLieu.gopDanhSachThiDua(cu: kq.danhSachThiDua, moi: ds)
            }

            if dtGop.coDuLieu {
                kq.doanhThu = dtGop
            }

            if kq.capNhatLuc.isEmpty {
                kq.capNhatLuc = TienIchNgay.hienThiGioPhut.string(from: Date())
            }

            DispatchQueue.main.async {
                hoanTat(kq)
            }
        }
    }

    private func xuLyNhomBangThiDuaDuPhong(_ cacPhanTu: [([PhanTuVanBan], String?)]) -> [DongThiDua] {
        var dsTongHop: [DongThiDua] = []
        var idx = 0
        while idx < cacPhanTu.count {
            let (pt1, wm1) = cacPhanTu[idx]
            if idx + 1 < cacPhanTu.count {
                let (pt2, wm2) = cacPhanTu[idx + 1]
                let dsCap = ghepCapAnhThiDua(phanTu1: pt1, watermark1: wm1, phanTu2: pt2, watermark2: wm2)
                if !dsCap.isEmpty {
                    dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsCap)
                }
                idx += 2
            } else {
                let (ds1, _, _, _) = phanTichThiDuaOffline(phanTu: pt1, tenNganhGoiY: nil)
                if !ds1.isEmpty {
                    dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: ds1)
                }
                idx += 1
            }
        }
        return dsTongHop
    }

    // MARK: - 1. Quét danh sách ảnh chụp màn hình Thi Đua (nếu chọn nhầm ảnh Doanh thu vẫn tự tách sang Doanh thu, không đưa vào Thi đua)

    func quetAnhThiDua(
        danhSachAnh: [UIImage],
        danhSachHienCo: [DongThiDua] = [],
        laRealtime: Bool = false,
        tenNganhGoiY: String? = nil,
        tienTrinh: @escaping (String) -> Void,
        hoanTat: @escaping (KetQuaQuetThiDua) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var dsTongHop: [DongThiDua] = []
            var cacKhoiNV: [KetQuaThiDuaNhanVienKhoi] = []
            var dtQuetDuoc = ThongTinDoanhThu()
            var capNhatOffline = ""
            var donViOffline = ""

            var cacPhanTuThiDua: [([PhanTuVanBan], String?)] = []

            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh("Đang quét chữ (Apple Vision) ảnh \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                let (cn, dv, wm) = self.trichThongTinChungThiDua(phanTu: phanTu)
                if capNhatOffline.isEmpty, let cn = cn, !cn.isEmpty {
                    capNhatOffline = cn
                }
                if donViOffline.isEmpty, let dv = dv, !dv.isEmpty {
                    donViOffline = dv
                }

                // Nếu là ảnh Doanh thu Siêu thị (DT thực / DT quy đổi): tách sang Doanh thu, tuyệt đối không đưa vào bảng Thi đua
                if self.laAnhDoanhThuSieuThi(phanTu: phanTu) {
                    let dt = self.phanTichDoanhThu(phanTu: phanTu)
                    if dt.coDuLieu {
                        dtQuetDuoc = dtQuetDuoc.gop(voi: dt, laRealtime: laRealtime)
                        continue
                    }
                }

                // Kiểm tra xem có phải ảnh bảng Thực hiện nhân viên không
                let coCotHangTrongST = phanTu.contains { pt in
                    let u = self.boDau(pt.chu)
                    return pt.y < 0.22 && (
                        u.contains("HANG TRONG") ||
                        u.contains("TOP/BOTT") ||
                        u.contains("CON / VUOT") ||
                        u.contains("NHAN VIEN")
                    )
                }
                if coCotHangTrongST {
                    if let khoiNV = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, tenNganhGoiY: tenNganhGoiY, watermark: wm),
                       !khoiNV.danhSach.isEmpty {
                        cacKhoiNV.append(khoiNV)
                    }
                } else {
                    cacPhanTuThiDua.append((phanTu, wm))
                }
            }

            var cacPhanTuBang2Cot: [([PhanTuVanBan], String?)] = []
            for (pt, wm) in cacPhanTuThiDua {
                let dsLuoiThe = self.phanTichThiDuaLuoiThe2Cot(phanTu: pt, watermark: wm)
                if !dsLuoiThe.isEmpty {
                    dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsLuoiThe)
                } else {
                    cacPhanTuBang2Cot.append((pt, wm))
                }
            }

            if !cacPhanTuBang2Cot.isEmpty {
                if cacPhanTuBang2Cot.count == 1,
                   !danhSachHienCo.isEmpty,
                   (danhSachHienCo.allSatisfy({ $0.target <= 0 }) || danhSachHienCo.allSatisfy({ $0.thucHien <= 0 })) {
                    let (pt2, wm2) = cacPhanTuBang2Cot[0]
                    let (_, cacSo2) = self.trichXuatSoCotPhaiTuTrenXuong(phanTu: pt2, watermark: wm2)
                    let dangThieuTarget = danhSachHienCo.allSatisfy({ $0.target <= 0 })
                    var capNhat = danhSachHienCo
                    for i in 0..<min(capNhat.count, cacSo2.count) {
                        if dangThieuTarget {
                            capNhat[i].target = cacSo2[i].giaTri
                        } else {
                            capNhat[i].thucHien = cacSo2[i].giaTri
                        }
                    }
                    dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: capNhat)
                } else {
                    var idx = 0
                    while idx < cacPhanTuBang2Cot.count {
                        let (pt1, wm1) = cacPhanTuBang2Cot[idx]
                        if idx + 1 < cacPhanTuBang2Cot.count {
                            let (pt2, wm2) = cacPhanTuBang2Cot[idx + 1]
                            let dsCap = self.ghepCapAnhThiDua(phanTu1: pt1, watermark1: wm1, phanTu2: pt2, watermark2: wm2)
                            if !dsCap.isEmpty {
                                dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: dsCap)
                            }
                            idx += 2
                        } else {
                            let (ds1, _, _, _) = self.phanTichThiDuaOffline(phanTu: pt1, tenNganhGoiY: tenNganhGoiY)
                            if !ds1.isEmpty {
                                dsTongHop = KhoDuLieu.gopDanhSachThiDua(cu: dsTongHop, moi: ds1)
                            }
                            idx += 1
                        }
                    }
                }
            }

            let ketQua = KetQuaQuetThiDua(
                danhSach: dsTongHop,
                thiDuaNhanVien: cacKhoiNV,
                doanhThuQuetDuoc: dtQuetDuoc.coDuLieu ? dtQuetDuoc : nil,
                capNhatLuc: capNhatOffline.isEmpty ? TienIchNgay.hienThiGioPhut.string(from: Date()) : capNhatOffline,
                thongTinDonVi: donViOffline
            )
            DispatchQueue.main.async {
                hoanTat(ketQua)
            }
        }
    }

    // MARK: - 2. Quét danh sách ảnh chụp bảng Thực hiện Nhân viên theo Ngành hàng

    func quetAnhThiDuaNhanVien(
        danhSachAnh: [UIImage],
        tenNganhGoiY: String? = nil,
        tienTrinh: ((String) -> Void)? = nil,
        hoanTat: @escaping ([KetQuaThiDuaNhanVienKhoi]) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var cacKhoi: [KetQuaThiDuaNhanVienKhoi] = []
            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh?("Đang đọc ảnh Thực hiện NV \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                var watermark: String?
                for pt in phanTu where pt.y < 0.16 {
                    if let range = pt.chu.range(of: "\\b\\d{4,7}(?=\\s*-)", options: .regularExpression) {
                        watermark = String(pt.chu[range])
                    }
                }
                if let khoi = self.phanTichThiDuaNhanVienOffline(phanTu: phanTu, tenNganhGoiY: tenNganhGoiY, watermark: watermark),
                   !khoi.danhSach.isEmpty {
                    cacKhoi.append(khoi)
                }
            }
            DispatchQueue.main.async {
                hoanTat(cacKhoi)
            }
        }
    }

    // MARK: - 3. Quét danh sách ảnh chụp màn hình Doanh thu (Lũy kế hoặc Realtime: DT thực & DT quy đổi)

    func quetAnhDoanhThu(
        danhSachAnh: [UIImage],
        laRealtime: Bool = false,
        tienTrinh: ((String) -> Void)? = nil,
        hoanTat: @escaping (ThongTinDoanhThu) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var ketQuaGop = ThongTinDoanhThu()
            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh?("Đang đọc ảnh Doanh thu \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                let kqAnh = self.phanTichDoanhThu(phanTu: phanTu)
                ketQuaGop = ketQuaGop.gop(voi: kqAnh, laRealtime: laRealtime)
            }
            DispatchQueue.main.async {
                hoanTat(ketQuaGop)
            }
        }
    }

    // MARK: - 4. Quét danh sách ảnh chụp bảng Doanh thu hợp nhất theo Nhân viên

    func quetAnhDoanhThuNhanVien(
        danhSachAnh: [UIImage],
        tienTrinh: ((String) -> Void)? = nil,
        hoanTat: @escaping ([DoanhThuNhanVienItem]) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            var dsQuet: [DoanhThuNhanVienItem] = []
            for (chiSo, anh) in danhSachAnh.enumerated() {
                DispatchQueue.main.async {
                    tienTrinh?("Đang đọc ảnh Doanh thu NV \(chiSo + 1)/\(danhSachAnh.count)...")
                }
                let phanTu = self.thucHienOCR(anh: anh)
                dsQuet.append(contentsOf: self.phanTichDoanhThuNhanVienOffline(phanTu: phanTu))
            }
            DispatchQueue.main.async {
                hoanTat(dsQuet)
            }
        }
    }

    // MARK: - Bước 1: Apple Vision OCR trên iPhone

    private func thucHienOCR(anh: UIImage) -> [PhanTuVanBan] {
        guard let cgImage = anh.cgImage else { return [] }

        var phanTu: [PhanTuVanBan] = []
        let yeuCau = VNRecognizeTextRequest { request, _ in
            guard let ketQua = request.results as? [VNRecognizedTextObservation] else { return }
            for obs in ketQua {
                guard let ungVien = obs.topCandidates(1).first else { continue }
                let chu = ungVien.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !chu.isEmpty else { continue }
                let box = obs.boundingBox
                let yTrenXuong = 1.0 - box.origin.y - box.size.height
                phanTu.append(
                    PhanTuVanBan(
                        chu: chu,
                        x: box.origin.x,
                        y: yTrenXuong,
                        rong: box.size.width,
                        cao: box.size.height
                    )
                )
            }
        }

        yeuCau.recognitionLevel = .accurate
        yeuCau.usesLanguageCorrection = true
        yeuCau.recognitionLanguages = ["vi-VN", "en-US"]

        var phanTuSoBoSung: [PhanTuVanBan] = []
        let yeuCauSo = VNRecognizeTextRequest { request, _ in
            guard let ketQua = request.results as? [VNRecognizedTextObservation] else { return }
            for obs in ketQua {
                guard let ungVien = obs.topCandidates(1).first else { continue }
                let chu = ungVien.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !chu.isEmpty else { continue }
                guard chu.range(of: "^[+\\-−–]?[0-9]+([.,][0-9]+)?%?$", options: .regularExpression) != nil else { continue }
                let box = obs.boundingBox
                let yTrenXuong = 1.0 - box.origin.y - box.size.height
                phanTuSoBoSung.append(
                    PhanTuVanBan(
                        chu: chu,
                        x: box.origin.x,
                        y: yTrenXuong,
                        rong: box.size.width,
                        cao: box.size.height
                    )
                )
            }
        }
        yeuCauSo.recognitionLevel = .accurate
        yeuCauSo.usesLanguageCorrection = false
        yeuCauSo.minimumTextHeight = 0.006

        let xuLy = VNImageRequestHandler(cgImage: cgImage, orientation: anh.cgImageOrientation, options: [:])
        try? xuLy.perform([yeuCau, yeuCauSo])

        for ptSo in phanTuSoBoSung {
            if let idx = phanTu.firstIndex(where: { pt in
                abs(pt.y - ptSo.y) < 0.016 && abs(pt.x - ptSo.x) < 0.045 &&
                pt.chu.range(of: "\\d", options: .regularExpression) != nil
            }) {
                let chuSo = ptSo.chu.replacingOccurrences(of: "−", with: "-").replacingOccurrences(of: "–", with: "-")
                let chuCu = phanTu[idx].chu.replacingOccurrences(of: "−", with: "-").replacingOccurrences(of: "–", with: "-")
                if chuSo.hasPrefix("-") && !chuCu.hasPrefix("-") {
                    phanTu[idx] = ptSo
                }
            } else {
                phanTu.append(ptSo)
            }
        }
        return phanTu
    }

    // MARK: - Bước 2A: Bộ phân tích bố cục Thi Đua ĐMX & Thực hiện NV

    private func phanTichThiDuaOffline(
        phanTu: [PhanTuVanBan],
        tenNganhGoiY: String? = nil
    ) -> ([DongThiDua], [KetQuaThiDuaNhanVienKhoi], String?, String?) {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) {
            return ([], [], nil, nil)
        }

        var capNhatLuc: String?
        var thongTinDonVi: String?
        var maNhanVienWatermark: String?

        for pt in phanTu {
            if pt.chu.localizedCaseInsensitiveContains("Cập nhật lúc") || pt.chu.range(of: "\\d{2}:\\d{2}:\\d{2}", options: .regularExpression) != nil {
                if capNhatLuc == nil {
                    capNhatLuc = pt.chu.replacingOccurrences(of: "Cập nhật lúc:", with: "").trimmingCharacters(in: .whitespaces)
                } else if !capNhatLuc!.contains(pt.chu) {
                    capNhatLuc = "\(capNhatLuc!) \(pt.chu)"
                }
            }
            if pt.y < 0.16, let range = pt.chu.range(of: "\\b\\d{4,7}(?=\\s*-)", options: .regularExpression) {
                maNhanVienWatermark = String(pt.chu[range])
            }
            if pt.chu.hasPrefix("ĐML_") || pt.chu.hasPrefix("ĐMX_") || pt.chu.hasPrefix("TGDĐ_") {
                if thongTinDonVi == nil {
                    thongTinDonVi = pt.chu
                }
            }
        }

        let coCotHangTrongST = phanTu.contains { pt in
            let u = boDau(pt.chu)
            return pt.y < 0.22 && (
                u.contains("HANG TRONG") ||
                u.contains("TOP/BOTT") ||
                u.contains("CON / VUOT") ||
                u.contains("NHAN VIEN")
            )
        }

        if coCotHangTrongST {
            if let khoiNV = phanTichThiDuaNhanVienOffline(phanTu: phanTu, tenNganhGoiY: tenNganhGoiY, watermark: maNhanVienWatermark) {
                return ([], [khoiNV], capNhatLuc, thongTinDonVi)
            }
            return ([], [], capNhatLuc, thongTinDonVi)
        }

        let dsLuoiThe = phanTichThiDuaLuoiThe2Cot(phanTu: phanTu, watermark: maNhanVienWatermark)
        if !dsLuoiThe.isEmpty {
            return (dsLuoiThe, [], capNhatLuc, thongTinDonVi)
        }

        let dsHaiCot = phanTichThiDuaHaiCot(phanTu: phanTu, watermark: maNhanVienWatermark)
        if !dsHaiCot.isEmpty {
            return (dsHaiCot, [], capNhatLuc, thongTinDonVi)
        }

        let mocChiTieu = phanTu.filter { pt in
            let khongDau = boDau(pt.chu)
            let laChiTieu = khongDau.contains("SO LUONG") || khongDau.contains("DOANH THU")
            return laChiTieu && pt.x >= 0.22 && pt.x <= 0.55 && pt.y > 0.12
        }.sorted { $0.y < $1.y }

        var ketQua: [DongThiDua] = []

        for (chiSo, moc) in mocChiTieu.enumerated() {
            let yTieuDe = moc.y
            let yGioiHanDuoi: CGFloat = (chiSo + 1 < mocChiTieu.count) ? mocChiTieu[chiSo + 1].y - 0.015 : 0.98

            let loai: LoaiChiTieuThiDua = boDau(moc.chu).contains("DOANH") ? .doanhThu : .soLuong

            let phanTuTen = phanTu.filter { pt in
                pt.x < 0.31 && abs(pt.y - yTieuDe) < 0.045 && !laChuoiRac(pt.chu, watermark: maNhanVienWatermark)
            }.sorted {
                if abs($0.y - $1.y) < 0.008 { return $0.x < $1.x }
                return $0.y < $1.y
            }

            let tenNganhHang = phanTuTen
                .map { $0.chu }
                .joined(separator: " ")
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !tenNganhHang.isEmpty, !laTenTheDoanhThuKhongPhaiThiDua(tenNganhHang) else { continue }

            let vungDuLieu = phanTu.filter { pt in
                pt.y > yTieuDe + 0.015 && pt.y < min(yGioiHanDuoi, yTieuDe + 0.14) && pt.x >= 0.28
            }

            let soThucHien = timGiaTriSo(trong: vungDuLieu.filter { $0.x >= 0.28 && $0.x < 0.50 }, watermark: maNhanVienWatermark)
            let soTarget = timGiaTriSo(trong: vungDuLieu.filter { $0.x >= 0.50 && $0.x < 0.69 }, watermark: maNhanVienWatermark)
            let soHT = timGiaTriSo(trong: vungDuLieu.filter { $0.x >= 0.69 && $0.x < 0.84 }, watermark: maNhanVienWatermark)
            let soDuBao = timGiaTriSo(trong: vungDuLieu.filter { $0.x >= 0.84 }, watermark: maNhanVienWatermark)

            guard let thucHien = soThucHien, let target = soTarget else { continue }

            let dong = DongThiDua(
                tenNganhHangGoc: tenNganhHang,
                tenNganhHang: tenNganhHang,
                loaiChiTieu: loai,
                thucHien: thucHien,
                target: target,
                phanTramHTGoc: soHT,
                phanTramDuBaoGoc: soDuBao
            )
            ketQua = KhoDuLieu.gopDanhSachThiDua(cu: ketQua, moi: [dong])
        }

        return (ketQua, [], capNhatLuc, thongTinDonVi)
    }

    // MARK: - Bước 2A.1: Bộ phân tích Lưới Thẻ Thi Đua 2 Cột (Quét đủ Thực hiện, Target, DT/SL Dự kiến, % HT tháng & % Dự kiến hoàn thành)

    private func phanTichThiDuaLuoiThe2Cot(phanTu: [PhanTuVanBan], watermark: String?) -> [DongThiDua] {
        // Tuyệt đối không phân tích nếu đây là ảnh chụp màn hình Doanh thu Siêu thị
        if laAnhDoanhThuSieuThi(phanTu: phanTu) {
            return []
        }

        let coDauHieuLuoiThe = phanTu.contains { pt in
            let u = boDau(pt.chu)
            return u.contains("DU KIEN HOAN") || u.contains("HT THANG") || u.contains("HT NGAY") ||
                   u.contains("TARGET NGAY") || u.contains("DT DU KIEN") || u.contains("SL DU KIEN")
        }
        let coTargetTrai = phanTu.contains { $0.x < 0.48 && boDau($0.chu).contains("TARGET") }
        let coTargetPhai = phanTu.contains { $0.x >= 0.48 && boDau($0.chu).contains("TARGET") }
        let coTieuDeTheTrai = phanTu.contains { $0.x < 0.45 && boDau($0.chu).range(of: "^T\\d{1,2}\\b", options: .regularExpression) != nil }
        let coTieuDeThePhai = phanTu.contains { $0.x >= 0.48 && boDau($0.chu).range(of: "^T\\d{1,2}\\b", options: .regularExpression) != nil }

        guard coDauHieuLuoiThe || (coTargetTrai && coTargetPhai) || (coTieuDeTheTrai && coTieuDeThePhai) else {
            return []
        }

        let cacYHeader = phanTu.compactMap { pt -> CGFloat? in
            guard pt.y < 0.15 else { return nil }
            let u = boDau(pt.chu)
            if u.contains("DOANH THU HOP") || u.contains("HOP NHAT") || u.contains("CAP NHAT") ||
               u.contains("DUNG NGUYEN") || (watermark != nil && u.contains(watermark!)) {
                return pt.y + pt.cao
            }
            return nil
        }
        let yBatDauTrang: CGFloat = (cacYHeader.max() ?? -0.01) + 0.010

        // Tìm ranh giới giữa cột thẻ Trái và cột thẻ Phải (hỗ trợ cả ảnh có lề đen bên trái)
        let cacXDauCotPhai = phanTu.compactMap { pt -> CGFloat? in
            guard pt.x >= 0.48 && pt.x <= 0.65 else { return nil }
            let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
            if u.range(of: "^T\\d{1,2}\\b", options: .regularExpression) != nil ||
               u.contains("THUC HIEN") || u.contains("HT THANG") || u.contains("HT NGAY") ||
               (pt.chu.contains("%") && chuyenChuoiThanhSoDoanhThu(pt.chu) != nil) {
                return pt.x
            }
            return nil
        }
        let xRanhGioiCot: CGFloat
        if let minXPhai = cacXDauCotPhai.min() {
            xRanhGioiCot = max(0.495, min(0.535, minXPhai - 0.025))
        } else {
            xRanhGioiCot = 0.50
        }

        let theCotTrai = phanTichCotTheThiDua(phanTu: phanTu, xMin: 0.0, xMax: xRanhGioiCot, yBatDauTrang: max(0.002, yBatDauTrang), watermark: watermark)
        let theCotPhai = phanTichCotTheThiDua(phanTu: phanTu, xMin: xRanhGioiCot, xMax: 1.0, yBatDauTrang: max(0.002, yBatDauTrang), watermark: watermark)

        var ketQua: [DongThiDua] = []
        let soHang = max(theCotTrai.count, theCotPhai.count)
        for i in 0..<soHang {
            if i < theCotTrai.count {
                ketQua = KhoDuLieu.gopDanhSachThiDua(cu: ketQua, moi: [theCotTrai[i]])
            }
            if i < theCotPhai.count {
                ketQua = KhoDuLieu.gopDanhSachThiDua(cu: ketQua, moi: [theCotPhai[i]])
            }
        }
        return ketQua
    }

    private func phanTichCotTheThiDua(
        phanTu: [PhanTuVanBan],
        xMin: CGFloat,
        xMax: CGFloat,
        yBatDauTrang: CGFloat,
        watermark: String?
    ) -> [DongThiDua] {
        let phanTuCot = phanTu.filter { pt in
            let xTam = pt.x + min(pt.rong, 0.15) / 2.0
            return xTam >= xMin && xTam < xMax && pt.y >= yBatDauTrang && pt.y < 0.996
        }
        guard !phanTuCot.isEmpty else { return [] }

        let xTraiThuc = phanTuCot.map(\.x).min() ?? xMin
        let xPhaiThuc = phanTuCot.map { $0.x + min($0.rong, 0.15) }.max() ?? xMax
        let xGiua = (xTraiThuc + xPhaiThuc) / 2.0 - 0.015

        var ungVienDauThe: [CGFloat] = []
        for pt in phanTuCot {
            let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
            let uGon = u.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
            if pt.x >= xPhaiThuc - 0.13 && (uGon == "DT" || uGon == "SL" || uGon == "OT" || uGon == "0T" || uGon == "5L" || uGon == "SI" || uGon == "PR") {
                ungVienDauThe.append(pt.y)
            } else if pt.x < xGiua && u.range(of: "^T\\d{1,2}\\b", options: .regularExpression) != nil {
                ungVienDauThe.append(pt.y)
            }
        }
        ungVienDauThe.sort()

        var cacDauThe: [CGFloat] = []
        for y in ungVienDauThe {
            if let cuoi = cacDauThe.last, y - cuoi < 0.12 {
                cacDauThe[cacDauThe.count - 1] = min(cuoi, y)
            } else {
                cacDauThe.append(y)
            }
        }

        let cacYMocTHTG = phanTuCot.compactMap { pt -> CGFloat? in
            let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
            if u.contains("THUC HIEN") || (u.hasPrefix("TARGET") && !u.contains("TARGET TRON KY")) {
                return pt.y
            }
            return nil
        }.sorted()

        for yMoc in cacYMocTHTG {
            let daCoDauThe = cacDauThe.contains { yDau in
                yMoc > yDau && (yMoc - yDau) < 0.24
            }
            if !daCoDauThe {
                let yUocLuong = max(yBatDauTrang, yMoc - 0.115)
                if !cacDauThe.contains(where: { abs($0 - yUocLuong) < 0.10 }) {
                    cacDauThe.append(yUocLuong)
                    cacDauThe.sort()
                }
            }
        }

        guard !cacDauThe.isEmpty else { return [] }

        var danhSachThe: [DongThiDua] = []

        for (k, yDau) in cacDauThe.enumerated() {
            let yTrenThe: CGFloat = max(yBatDauTrang, yDau - 0.014)
            let yDuoiThe: CGFloat = (k + 1 < cacDauThe.count)
                ? (cacDauThe[k + 1] - 0.014)
                : 0.996

            let trongThe = phanTuCot.filter { $0.y >= yTrenThe && $0.y <= yDuoiThe }
            guard !trongThe.isEmpty else { continue }

            // Chỉ lấy các số % nằm bên dưới tiêu đề thẻ (pt.y >= yDau + 0.015) để không dính phần đáy của thẻ bị cắt ở mép trên ảnh
            let cacPhanTuPhanTramTrai = trongThe.filter { pt in
                pt.y >= yDau + 0.015 && pt.x < xGiua && pt.chu.contains("%") && chuyenChuoiThanhSoDoanhThu(pt.chu) != nil
            }.sorted { $0.y < $1.y }

            let yBigPct: CGFloat = cacPhanTuPhanTramTrai.first?.y ?? (yDau + 0.065)
            let yBotPct: CGFloat = (cacPhanTuPhanTramTrai.count >= 2)
                ? cacPhanTuPhanTramTrai.last!.y
                : (yDuoiThe - 0.012)

            var phanTramDuBao = cacPhanTuPhanTramTrai.first.flatMap { chuyenChuoiThanhSoDoanhThu($0.chu) }
            var phanTramHT: Double? = (cacPhanTuPhanTramTrai.count >= 2)
                ? cacPhanTuPhanTramTrai.last.flatMap { chuyenChuoiThanhSoDoanhThu($0.chu) }
                : nil

            var loai: LoaiChiTieuThiDua = .doanhThu
            for pt in trongThe {
                let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
                let uGon = u.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
                if u.contains("SL DU") || uGon == "SL" || uGon == "5L" || uGon == "SI" {
                    loai = .soLuong
                    break
                } else if u.contains("DT DU") || uGon == "DT" || uGon == "0T" || uGon == "OT" {
                    loai = .doanhThu
                }
            }

            var yGioiHanTieuDe = yBigPct - 0.004
            for pt in trongThe where pt.y < yBigPct + 0.025 {
                let u = boDau(pt.chu)
                if (pt.chu.contains("%") && pt.y >= yDau + 0.015) ||
                   u.contains("DU KIEN") ||
                   u.contains("HOAN THANH") ||
                   u.contains("HT NGAY") ||
                   u.contains("HT THANG") ||
                   ((u == "HOAN" || u == "THANH" || u == "HT" || u == "NGAY") && pt.x > xGiua) ||
                   u.contains("KHONG TINH") ||
                   u.contains("TINH HANG") ||
                   u.contains("CHAY THEO") ||
                   u.contains("THUONG HIEU") {
                    yGioiHanTieuDe = min(yGioiHanTieuDe, pt.y - 0.004)
                }
            }

            let phanTuTen = trongThe.filter { pt in
                guard pt.y >= yDau - 0.012 && pt.y <= yGioiHanTieuDe else { return false }
                let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
                let uGon = u.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
                if uGon == "DT" || uGon == "SL" || uGon == "OT" || uGon == "0T" || uGon == "5L" || uGon == "SI" || uGon == "PR" {
                    return false
                }
                if pt.x >= xPhaiThuc - 0.125 && uGon.count <= 3 {
                    return false
                }
                if u.contains("KHONG TINH") || u.contains("TINH HANG") || u.contains("CHAY THEO") || u.contains("THUONG HIEU") {
                    return false
                }
                if let wm = watermark, u.contains(wm) || u.contains("DUNG NGUYEN") {
                    return false
                }
                return true
            }

            let sapXepY = phanTuTen.sorted { $0.y < $1.y }
            var cacDongTen: [(y: CGFloat, tu: [PhanTuVanBan])] = []
            for pt in sapXepY {
                if let idx = cacDongTen.indices.last, abs(pt.y - cacDongTen[idx].y) < 0.014 {
                    cacDongTen[idx].tu.append(pt)
                } else {
                    cacDongTen.append((y: pt.y, tu: [pt]))
                }
            }

            let chuoiTen = cacDongTen
                .flatMap { dong in dong.tu.sorted { $0.x < $1.x }.map(\.chu) }
                .joined(separator: " ")

            let tenSach = lamSachTenChuongTrinh(chuoiTen)
            guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }

            // Quét toàn bộ các hàng số bên dưới thanh tiến độ:
            // - Hàng trên: THỰC HIỆN (trái) & TARGET (phải)
            // - Hàng dưới (ở tab Lũy kế): % HT THÁNG (trái) & DT/SL DỰ KIẾN (phải)
            let vungSoDuoiThanh = trongThe.filter { pt in
                guard pt.y > yBigPct + 0.018 && pt.y <= yDuoiThe else { return false }
                let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
                if u.contains("THUC") || u.contains("HIEN") || u.contains("TARGET") ||
                   u.contains("NGAY") || u.contains("THANG") || u.contains("DU KIEN") ||
                   u.contains("HOAN") || u.contains("THANH") || u == "HT" || u == "% HT" || u == ">" {
                    return false
                }
                return !trichCacSoTheThiDua(trong: pt.chu).isEmpty
            }.sorted {
                if abs($0.y - $1.y) < 0.018 { return $0.x < $1.x }
                return $0.y < $1.y
            }

            var cacHangSo: [(y: CGFloat, phanTu: [PhanTuVanBan])] = []
            for pt in vungSoDuoiThanh {
                if let idx = cacHangSo.indices.last, abs(pt.y - cacHangSo[idx].y) < 0.025 {
                    cacHangSo[idx].phanTu.append(pt)
                } else {
                    cacHangSo.append((y: pt.y, phanTu: [pt]))
                }
            }

            var thucHien: Double?
            var target: Double?
            var duKien: Double?

            // Tìm mốc Y của nhãn hàng thứ 2 (% HT THÁNG / DT DỰ KIẾN / SL DỰ KIẾN) nếu OCR đọc được nhãn
            let cacYMocHang2 = trongThe.compactMap { pt -> CGFloat? in
                guard pt.y > yBigPct + 0.03 else { return nil }
                let u = boDau(pt.chu)
                if u.contains("HT THANG") || u.contains("DT DU") || u.contains("SL DU") {
                    return pt.y
                }
                return nil
            }
            let yMocHang2 = cacYMocHang2.min()

            for (chiSoHang, hang) in cacHangSo.enumerated() {
                let laHangDuKien: Bool
                if cacHangSo.count >= 2 {
                    laHangDuKien = (chiSoHang >= 1)
                } else if let yMoc2 = yMocHang2, hang.y > yMoc2 {
                    laHangDuKien = true
                } else if cacPhanTuPhanTramTrai.count >= 2 && abs(hang.y - yBotPct) < 0.025 {
                    laHangDuKien = true
                } else {
                    laHangDuKien = false
                }

                for pt in hang.phanTu.sorted(by: { $0.x < $1.x }) {
                    let cacSo = trichCacSoTheThiDua(trong: pt.chu)
                    guard !cacSo.isEmpty else { continue }

                    if !laHangDuKien {
                        if cacSo.count >= 2 && pt.rong > 0.18 {
                            if thucHien == nil { thucHien = cacSo[0] }
                            if target == nil { target = cacSo[1] }
                        } else if let so = cacSo.first {
                            if pt.x < xGiua {
                                if !pt.chu.contains("%") && thucHien == nil {
                                    thucHien = so
                                }
                            } else {
                                if !pt.chu.contains("%") && target == nil {
                                    target = so
                                }
                            }
                        }
                    } else {
                        if cacSo.count >= 2 && pt.rong > 0.18 {
                            if phanTramHT == nil { phanTramHT = cacSo[0] }
                            if duKien == nil { duKien = cacSo[1] }
                        } else if let so = cacSo.first {
                            if pt.x < xGiua {
                                if phanTramHT == nil { phanTramHT = so }
                            } else if !pt.chu.contains("%") {
                                if duKien == nil { duKien = so }
                            }
                        }
                    }
                }
            }

            // Nếu thẻ ở sát mép dưới ảnh bị cắt cụt hoàn toàn phần số liệu thì bỏ qua để tránh tạo dòng 0/0 rác
            if thucHien == nil && target == nil && phanTramDuBao == nil && phanTramHT == nil && duKien == nil {
                continue
            }

            // Nếu là thẻ Realtime (chỉ có 1 số % duy nhất ở trên cùng và không có dòng DT DỰ KIẾN)
            if phanTramHT == nil && duKien == nil {
                phanTramHT = phanTramDuBao
            }

            let soTH = thucHien ?? 0.0
            let soTG: Double
            if let tg = target, tg > 0 {
                // Kiểm tra nếu OCR bị mất phần thập phân hoặc dấu phẩy nhưng có cả duKien và phanTramDuBao để đối chiếu
                if let dk = duKien, let ptDB = phanTramDuBao, ptDB > 1.0 {
                    let tgUocTuDK = dk / (ptDB / 100.0)
                    if abs(tg - tgUocTuDK) > max(10.0, tgUocTuDK * 0.25) {
                        soTG = (loai == .soLuong) ? tgUocTuDK.rounded() : ((tgUocTuDK * 100).rounded() / 100)
                    } else {
                        soTG = tg
                    }
                } else {
                    soTG = tg
                }
            } else if let dk = duKien, let ptDB = phanTramDuBao, ptDB > 0.1 {
                let uocLuong = dk / (ptDB / 100.0)
                soTG = (loai == .soLuong) ? uocLuong.rounded() : ((uocLuong * 100).rounded() / 100)
            } else if soTH > 0, let pt = phanTramHT ?? phanTramDuBao, pt > 0.1 {
                let uocLuong = soTH / (pt / 100.0)
                soTG = (loai == .soLuong) ? uocLuong.rounded() : ((uocLuong * 100).rounded() / 100)
            } else {
                soTG = 0.0
            }

            // Nếu có Target và DT Dự kiến mà OCR chưa đọc được % Dự kiến hoặc % HT tháng thì tự bổ sung chính xác
            if phanTramDuBao == nil, let dk = duKien, soTG > 0.0001 {
                phanTramDuBao = ((dk / soTG) * 1000).rounded() / 10
            }
            if duKien == nil, let ptDB = phanTramDuBao, soTG > 0.0001, cacPhanTuPhanTramTrai.count >= 2 {
                let uocDK = soTG * (ptDB / 100.0)
                duKien = (loai == .soLuong) ? uocDK.rounded() : ((uocDK * 100).rounded() / 100)
            }

            let dong = DongThiDua(
                tenNganhHangGoc: tenSach,
                tenNganhHang: tenSach,
                loaiChiTieu: loai,
                thucHien: soTH,
                target: soTG,
                phanTramHTGoc: phanTramHT,
                phanTramDuBaoGoc: phanTramDuBao ?? phanTramHT,
                duKienGoc: duKien
            )
            danhSachThe.append(dong)
        }

        return danhSachThe
    }

    private func trichCacSoTheThiDua(trong chuoi: String) -> [Double] {
        let sach = chuoi.trimmingCharacters(in: .whitespacesAndNewlines)
        if sach.count == 1 {
            let mapKyTuDon: [String: Double] = [
                "O": 0, "o": 0, "Q": 0, "D": 0,
                "I": 1, "l": 1,
                "Z": 2, "S": 5, "B": 8
            ]
            if let v = mapKyTuDon[sach] {
                return [v]
            }
        }
        return trichCacSo(trong: sach)
    }

    // MARK: - Bước 2A.2: Bộ phân tích bố cục Thi Đua 2 cột

    private struct DongAnh1Tam {
        var ten: String
        var loai: LoaiChiTieuThiDua
        var giaTriCot1: Double
    }

    private func trichThongTinChungThiDua(phanTu: [PhanTuVanBan]) -> (capNhatLuc: String?, thongTinDonVi: String?, watermark: String?) {
        var capNhatLuc: String?
        var thongTinDonVi: String?
        var maNhanVienWatermark: String?

        for pt in phanTu {
            if pt.chu.localizedCaseInsensitiveContains("Cập nhật lúc") || pt.chu.range(of: "\\d{2}:\\d{2}:\\d{2}", options: .regularExpression) != nil {
                if capNhatLuc == nil {
                    capNhatLuc = pt.chu.replacingOccurrences(of: "Cập nhật lúc:", with: "").trimmingCharacters(in: .whitespaces)
                } else if !capNhatLuc!.contains(pt.chu) {
                    capNhatLuc = "\(capNhatLuc!) \(pt.chu)"
                }
            }
            if pt.y < 0.16, let range = pt.chu.range(of: "\\b\\d{4,7}(?=\\s*-)", options: .regularExpression) {
                maNhanVienWatermark = String(pt.chu[range])
            }
            if pt.chu.hasPrefix("ĐML_") || pt.chu.hasPrefix("ĐMX_") || pt.chu.hasPrefix("TGDĐ_") {
                if thongTinDonVi == nil {
                    thongTinDonVi = pt.chu
                }
            }
        }
        return (capNhatLuc, thongTinDonVi, maNhanVienWatermark)
    }

    private func ghepCapAnhThiDua(
        phanTu1: [PhanTuVanBan],
        watermark1: String?,
        phanTu2: [PhanTuVanBan],
        watermark2: String?
    ) -> [DongThiDua] {
        let (laTarget1, dsAnh1) = trichXuatDongTuAnh1(phanTu: phanTu1, watermark: watermark1)
        let (laTarget2, cacSoAnh2) = trichXuatSoCotPhaiTuTrenXuong(phanTu: phanTu2, watermark: watermark2)

        guard !dsAnh1.isEmpty else {
            let (dsCu1, _, _, _) = phanTichThiDuaOffline(phanTu: phanTu1, tenNganhGoiY: nil)
            let (dsCu2, _, _, _) = phanTichThiDuaOffline(phanTu: phanTu2, tenNganhGoiY: nil)
            return KhoDuLieu.gopDanhSachThiDua(cu: dsCu1, moi: dsCu2)
        }

        let anh1LaTarget: Bool
        if let t1 = laTarget1, let t2 = laTarget2, t1 != t2 {
            anh1LaTarget = t1
        } else if let t1 = laTarget1 {
            anh1LaTarget = t1
        } else if let t2 = laTarget2 {
            anh1LaTarget = !t2
        } else {
            anh1LaTarget = true
        }

        var ketQua: [DongThiDua] = []
        for (i, d1) in dsAnh1.enumerated() {
            let soAnh1 = d1.giaTriCot1
            let soAnh2: Double = (i < cacSoAnh2.count) ? cacSoAnh2[i].giaTri : 0
            let dong = DongThiDua(
                tenNganhHangGoc: d1.ten,
                tenNganhHang: d1.ten,
                loaiChiTieu: d1.loai,
                thucHien: anh1LaTarget ? soAnh2 : soAnh1,
                target: anh1LaTarget ? soAnh1 : soAnh2
            )
            ketQua.append(dong)
        }
        return ketQua
    }

    private func phanTichThiDuaHaiCot(phanTu: [PhanTuVanBan], watermark: String?) -> [DongThiDua] {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) { return [] }
        let (laTarget, dsAnh1) = trichXuatDongTuAnh1(phanTu: phanTu, watermark: watermark)
        guard !dsAnh1.isEmpty else { return [] }
        let laCotTarget = laTarget ?? true
        return dsAnh1.map { d in
            DongThiDua(
                tenNganhHangGoc: d.ten,
                tenNganhHang: d.ten,
                loaiChiTieu: d.loai,
                thucHien: laCotTarget ? 0 : d.giaTriCot1,
                target: laCotTarget ? d.giaTriCot1 : 0
            )
        }
    }

    private func trichXuatSoCotPhaiTuTrenXuong(
        phanTu: [PhanTuVanBan],
        watermark: String?
    ) -> (laCotTarget: Bool?, cacSo: [(y: CGFloat, giaTri: Double)]) {
        let vungHeader = phanTu.filter { $0.y > 0.08 && $0.y < 0.33 }
        let mocChuongTrinh = vungHeader.first { boDau($0.chu).contains("CHUONG TRINH") }
        let mocTarget = vungHeader.first { pt in
            let u = boDau(pt.chu)
            return pt.x > 0.50 && (u.contains("TARGET") || u.contains("ARGET"))
        }
        let mocThucHien = vungHeader.first { pt in
            let u = boDau(pt.chu)
            return pt.x > 0.50 && u.contains("THUC HIEN")
        }

        var laCotTarget: Bool?
        if let mt = mocTarget, let mth = mocThucHien {
            laCotTarget = mt.x >= mth.x
        } else if mocTarget != nil {
            laCotTarget = true
        } else if mocThucHien != nil {
            laCotTarget = false
        } else if phanTu.contains(where: { $0.y < 0.32 && $0.x > 0.55 && boDau($0.chu).contains("ARGET") }) {
            laCotTarget = true
        } else if phanTu.contains(where: { $0.y < 0.32 && $0.x > 0.55 && boDau($0.chu).contains("THUC HIEN") }) {
            laCotTarget = false
        }

        let yHeader = max(
            mocChuongTrinh?.y ?? 0,
            max(mocTarget?.y ?? 0, mocThucHien?.y ?? 0)
        )
        let yBatDau: CGFloat = (yHeader > 0.08) ? (yHeader + 0.015) : 0.21

        let ungVien = phanTu.compactMap { pt -> (y: CGFloat, x: CGFloat, giaTri: Double)? in
            guard (pt.x >= 0.64 || (pt.x >= 0.58 && pt.x + pt.rong >= 0.78)),
                  pt.y > yBatDau,
                  pt.y < 0.98 else {
                return nil
            }
            if let wm = watermark, pt.chu.contains(wm) { return nil }
            guard let so = chuyenTokenSoCotPhai(pt.chu) else { return nil }
            return (y: pt.y, x: pt.x, giaTri: so)
        }.sorted {
            if abs($0.y - $1.y) < 0.014 { return $0.x > $1.x }
            return $0.y < $1.y
        }

        var cacSoTheoHang: [(y: CGFloat, giaTri: Double)] = []
        for item in ungVien {
            if let last = cacSoTheoHang.last, abs(item.y - last.y) < 0.018 {
                continue
            }
            cacSoTheoHang.append((y: item.y, giaTri: item.giaTri))
        }

        return (laCotTarget, cacSoTheoHang)
    }

    private func trichXuatDongTuAnh1(
        phanTu: [PhanTuVanBan],
        watermark: String?
    ) -> (laCotTarget: Bool?, danhSach: [DongAnh1Tam]) {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) { return (nil, []) }
        let (laCotTarget, cacSoPhai) = trichXuatSoCotPhaiTuTrenXuong(phanTu: phanTu, watermark: watermark)
        guard !cacSoPhai.isEmpty else { return (laCotTarget, []) }

        let vungHeader = phanTu.filter { $0.y > 0.08 && $0.y < 0.33 }
        let mocChuongTrinh = vungHeader.first { boDau($0.chu).contains("CHUONG TRINH") }
        let mocTarget = vungHeader.first { pt in
            let u = boDau(pt.chu)
            return pt.x > 0.50 && (u.contains("TARGET") || u.contains("ARGET"))
        }
        let mocThucHien = vungHeader.first { pt in
            let u = boDau(pt.chu)
            return pt.x > 0.50 && u.contains("THUC HIEN")
        }
        let yHeader = max(
            mocChuongTrinh?.y ?? 0,
            max(mocTarget?.y ?? 0, mocThucHien?.y ?? 0)
        )
        let yBatDau: CGFloat = (yHeader > 0.08) ? (yHeader + 0.015) : 0.21

        var ketQua: [DongAnh1Tam] = []
        for (k, soHang) in cacSoPhai.enumerated() {
            let yTren: CGFloat = (k == 0) ? yBatDau : (cacSoPhai[k - 1].y + 0.008)
            let yDuoi: CGFloat = soHang.y + 0.012

            let phanTuTrongHang = phanTu.filter { pt in
                guard pt.x < 0.68 && pt.y > yTren && pt.y <= yDuoi else { return false }
                let u = boDau(pt.chu)
                if u.contains("CHUONG TRINH") || u.contains("CAN DICH") || u.contains("CHUA DAT") ||
                   u.contains("NGANH HANG") || u.contains("NHOM HANG") || u.contains("TAT CA (") {
                    return false
                }
                if let wm = watermark, u.contains(wm) || u.contains("DUNG NGUYEN") {
                    return false
                }
                return true
            }

            var coBadgeSL = false
            var coBadgeDT = false
            for pt in phanTuTrongHang {
                let u = boDau(pt.chu).trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                if u == "SL" || u == "5L" {
                    coBadgeSL = true
                } else if u == "DT" || u == "0T" {
                    coBadgeDT = true
                }
            }

            let phanTuTen = phanTuTrongHang.filter { pt in
                let chuSach = pt.chu.trimmingCharacters(in: .whitespacesAndNewlines)
                let u = boDau(chuSach)
                let uGon = u.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

                if uGon == "DT" || uGon == "SL" || uGon == "5L" || uGon == "0T" {
                    return false
                }
                if chuSach.hasPrefix("ĐML_") || chuSach.hasPrefix("ĐMX_") || chuSach.hasPrefix("TGDĐ_") ||
                   u.hasPrefix("DML_") || u.hasPrefix("DMX_") || u.hasPrefix("TGDD_") ||
                   u.contains("QUANG TRUNG") ||
                   u.range(of: "^[A-Z0-9]{2,5}_[A-Z0-9]{2,5}", options: .regularExpression) != nil {
                    return false
                }
                if laChuoiRac(chuSach, watermark: watermark) {
                    return false
                }
                if pt.x >= 0.58 && chuyenTokenSoCotPhai(chuSach) != nil {
                    return false
                }
                return true
            }.sorted {
                if abs($0.y - $1.y) < 0.012 { return $0.x < $1.x }
                return $0.y < $1.y
            }

            let chuoiGop = phanTuTen.map(\.chu).joined(separator: " ")
            let uGop = boDau(chuoiGop)

            let loai: LoaiChiTieuThiDua
            if uGop.contains("SO LUONG") || uGop.range(of: "\\bSL\\s*$", options: .regularExpression) != nil {
                loai = .soLuong
            } else if uGop.contains("DOANH THU") || uGop.range(of: "\\bDT\\s*$", options: .regularExpression) != nil {
                loai = .doanhThu
            } else if coBadgeSL && !coBadgeDT {
                loai = .soLuong
            } else {
                loai = .doanhThu
            }

            let tenSach = lamSachTenChuongTrinh(chuoiGop)
            guard tenSach.count >= 2, !laTenTheDoanhThuKhongPhaiThiDua(tenSach) else { continue }

            ketQua.append(DongAnh1Tam(ten: tenSach, loai: loai, giaTriCot1: soHang.giaTri))
        }

        return (laCotTarget, ketQua)
    }

    private func chuyenTokenSoCotPhai(_ chuoi: String) -> Double? {
        let s = chuoi
            .replacingOccurrences(of: "…", with: "")
            .replacingOccurrences(of: "...", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if s.range(of: "[A-Za-zÀ-ỹĐđ_]", options: .regularExpression) != nil {
            return nil
        }
        guard s.range(of: "^[+\\-]?\\d+([.,]\\d+)*$", options: .regularExpression) != nil else {
            return nil
        }
        return chuyenChuoiThanhSoDoanhThu(s)
    }

    private func lamSachTenChuongTrinh(_ chuoi: String) -> String {
        let s = chuoi
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "^[\\s\\-–—−•◦○●⊕⊖|¦/\\\\,:;]+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(?:\\s+|\\s*[\\|¦]\\s*)\\b(DT|SL|5L|0T)\\b\\s*$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.\\.\\.|…", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^[\\s\\|¦\\-–—−•◦○●⊕⊖/\\\\.:;,…]+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[\\s\\|¦\\-–—−•◦○●⊕⊖/\\\\.:;,…]+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\|\\s*\\|+", with: "|", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return s
    }

    // MARK: - Bước 2B: Phân tích ảnh Thực hiện Nhân viên theo Ngành hàng

    private func phanTichThiDuaNhanVienOffline(
        phanTu: [PhanTuVanBan],
        tenNganhGoiY: String? = nil,
        watermark: String? = nil
    ) -> KetQuaThiDuaNhanVienKhoi? {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) { return nil }

        var tenNganhHang = tenNganhGoiY ?? ""
        if tenNganhHang.isEmpty {
            if let mocTieuDe = phanTu.first(where: { pt in
                let u = boDau(pt.chu)
                return pt.y > 0.05 && pt.y < 0.20 && (
                    u.contains("DOANH THU") || u.contains("SO LUONG") || u.contains("THUC HIEN")
                )
            }) {
                let phanTuTen = phanTu.filter { pt in
                    pt.x < 0.31 && abs(pt.y - mocTieuDe.y) < 0.05 && !laChuoiRac(pt.chu, watermark: watermark)
                }.sorted {
                    if abs($0.y - $1.y) < 0.008 { return $0.x < $1.x }
                    return $0.y < $1.y
                }
                tenNganhHang = phanTuTen
                    .map(\.chu)
                    .joined(separator: " ")
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let cacDongNV = phanTu.filter { pt in
            guard pt.x < 0.45 && pt.y > 0.13 && pt.y < 0.96 else { return false }
            let u = boDau(pt.chu)
            if u.contains("ONLINE") || u.contains("TONG CONG") || u == "TONG" { return false }
            guard let range = pt.chu.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) else { return false }
            let ma = String(pt.chu[range])
            if let wm = watermark, ma == wm, u.contains("DUNG NGUYEN") { return false }
            return true
        }.sorted { $0.y < $1.y }

        var danhSach: [DongThiDuaNhanVienQuet] = []
        var daXetMa = Set<String>()

        for dong in cacDongNV {
            guard let range = dong.chu.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) else { continue }
            let maNV = String(dong.chu[range])
            if daXetMa.contains(maNV) { continue }

            let hoTen = dong.chu
                .replacingOccurrences(of: maNV, with: "")
                .replacingOccurrences(of: "[-–—]", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let cungHang = phanTu.filter { pt in
                pt.x >= 0.28 && pt.x < 0.72 && abs(pt.y - dong.y) < 0.03
            }.sorted { $0.x < $1.x }

            var thucHien: Double?
            var target: Double = 0

            for pt in cungHang {
                if pt.chu.contains("/") {
                    let parts = pt.chu.components(separatedBy: "/")
                    if let v1 = chuyenChuoiThanhSoDoanhThu(parts[0]) {
                        thucHien = v1
                        if parts.count > 1, let v2 = chuyenChuoiThanhSoDoanhThu(parts[1]) {
                            target = v2
                        }
                        break
                    }
                }
                if let val = chuyenChuoiThanhSo(pt.chu, watermark: watermark) {
                    thucHien = val
                    break
                }
            }

            if let th = thucHien {
                daXetMa.insert(maNV)
                danhSach.append(DongThiDuaNhanVienQuet(maNV: maNV, hoTen: hoTen, thucHien: th, target: target))
            }
        }

        return KetQuaThiDuaNhanVienKhoi(
            tenNganhHang: tenNganhHang.isEmpty ? "Ngành hàng" : tenNganhHang,
            danhSach: danhSach
        )
    }

    // MARK: - Bước 2C: Phân tích ảnh Doanh thu hợp nhất theo Nhân viên (Chỉ lọc 3 số liệu: Số Lượng, DT QĐ, % tỉ trọng)

    private func phanTichDoanhThuNhanVienOffline(phanTu: [PhanTuVanBan]) -> [DoanhThuNhanVienItem] {
        if laAnhDoanhThuSieuThi(phanTu: phanTu) { return [] }

        // 1. Nhận diện mã watermark chìm (ví dụ "54453" / "Dũng Nguyễn Thanh") để loại trừ tuyệt đối khỏi mã NV và số liệu
        var tapWatermark = Set<String>()
        let cacPhanTuTenWM = phanTu.filter { pt in
            let u = boDau(pt.chu)
            return u.contains("DUNG NGUYEN") || u.contains("NGUYEN THANH")
        }
        var demMaRoi: [String: Int] = [:]

        for pt in phanTu {
            let u = boDau(pt.chu)
            if pt.y < 0.14, let range = pt.chu.range(of: "\\b\\d{4,7}(?=\\s*-)", options: .regularExpression) {
                tapWatermark.insert(String(pt.chu[range]))
            }
            guard let range = pt.chu.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) else { continue }
            let ma = String(pt.chu[range])
            if u.contains("DUNG NGUYEN") || u.contains("NGUYEN THANH") {
                tapWatermark.insert(ma)
                continue
            }
            if cacPhanTuTenWM.contains(where: { abs($0.y - pt.y) < 0.09 && abs($0.x - pt.x) < 0.28 }) {
                tapWatermark.insert(ma)
                continue
            }
            let coGachNgang = pt.chu.contains("-") || pt.chu.contains("–") || pt.chu.contains("—")
            if !coGachNgang {
                demMaRoi[ma, default: 0] += 1
            }
        }
        for (ma, soLan) in demMaRoi where soLan >= 2 {
            tapWatermark.insert(ma)
        }

        // 2. Xác định mốc Y của dòng tiêu đề bảng (hỗ trợ cả ảnh cắt sát bảng ở y ~ 0.03 lẫn ảnh toàn màn hình)
        let cacYHeader = phanTu.compactMap { pt -> CGFloat? in
            guard pt.y < 0.42 else { return nil }
            let u = boDau(pt.chu)
            if u.contains("NHAN VIEN") || u.contains("SO LUONG") || u.contains("DOANH THU QD") ||
               u.contains("KHOAN VAY") || u.contains("TI TRONG") || u.contains("TY TRONG") {
                return pt.y + pt.cao
            }
            return nil
        }
        let yBatDauDong: CGFloat = cacYHeader.isEmpty ? 0.02 : min(0.32, (cacYHeader.max() ?? 0.04) + 0.010)
        let tapMaQuanLy = Set(KhoDuLieu.dungChung.caiDat.danhSachNhanVien.map(\.maNV))

        // 3. Lọc danh sách các dòng nhân viên ở cột bên trái
        let cacDongNV = phanTu.filter { pt in
            guard pt.x < 0.36 && pt.y > yBatDauDong && pt.y < 0.995 else { return false }
            let u = boDau(pt.chu)
            if u.contains("TONG") || u.contains("ONLINE") || u.contains("KHU VUC") ||
               u.contains("QUANG NGAI") || u.contains("DUNG NGUYEN") || u.contains("NGUYEN THANH") ||
               u.contains("NHAN VIEN") {
                return false
            }
            guard let range = pt.chu.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) else { return false }
            let ma = String(pt.chu[range])
            if tapWatermark.contains(ma) { return false }

            let coGachHoacChu = pt.chu.contains("-") || pt.chu.contains("–") || pt.chu.contains("—") ||
                pt.chu.range(of: "[A-Za-zÀ-ỹĐđ]", options: .regularExpression) != nil
            let coTenCungHang = phanTu.contains { other in
                other.x < 0.36 && abs(other.y - pt.y) < 0.022 &&
                other.chu.range(of: "[A-Za-zÀ-ỹĐđ]{2,}", options: .regularExpression) != nil &&
                !boDau(other.chu).contains("DUNG NGUYEN")
            }
            return coGachHoacChu || coTenCungHang || tapMaQuanLy.contains(ma)
        }.sorted { $0.y < $1.y }

        var ketQua: [DoanhThuNhanVienItem] = []
        var daXetMa = Set<String>()

        for dong in cacDongNV {
            guard let range = dong.chu.range(of: "\\b\\d{4,7}\\b", options: .regularExpression) else { continue }
            let maNV = String(dong.chu[range])
            if daXetMa.contains(maNV) { continue }

            // Ghép tên nhân viên trên cùng dòng ở cột trái (x < 0.34)
            let cacTuTen = phanTu.filter { pt in
                guard pt.x < 0.34 && abs(pt.y - dong.y) < 0.022 else { return false }
                let u = boDau(pt.chu)
                if u.contains("DUNG NGUYEN") || u.contains("NGUYEN THANH") { return false }
                for wm in tapWatermark where pt.chu.contains(wm) { return false }
                return true
            }.sorted { $0.x < $1.x }.map(\.chu).joined(separator: " ")

            let chuoiGocTen = cacTuTen.isEmpty ? dong.chu : cacTuTen
            let hoTen = chuoiGocTen
                .replacingOccurrences(of: maNV, with: "")
                .replacingOccurrences(of: "^[+\\s-–—−]+|[-–—−\\s]+$", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let yTamDong = dong.y + dong.cao * 0.5

            // Hàm trích xuất số trong khoảng cột [xMin, xMax], hỗ trợ cả số âm (-1, -2, -7, -4.0%, -15.5%) và số 0
            func laySoTrongCot(_ xMin: CGFloat, _ xMax: CGFloat, laCotPhanTram: Bool = false) -> Double? {
                let ungVien = phanTu.filter { pt in
                    let cungHang = abs((pt.y + pt.cao * 0.5) - yTamDong) < 0.025 || abs(pt.y - dong.y) < 0.024
                    guard cungHang && pt.x >= xMin - 0.02 && pt.x < xMax else { return false }
                    let u = boDau(pt.chu)
                    if u.contains("DUNG NGUYEN") || u.contains("NGUYEN THANH") { return false }
                    for wm in tapWatermark where pt.chu.contains(wm) { return false }
                    if pt.chu.range(of: "[A-Za-zÀ-ỹĐđ]", options: .regularExpression) != nil { return false }
                    return true
                }.sorted { $0.x < $1.x }

                guard !ungVien.isEmpty else { return nil }

                // Gom các mảnh ký tự kề nhau trong cùng một cột (ví dụ dấu "-" rời trước số "1", "2", "7", "4.0%")
                var cacCumChuoi: [(chuoi: String, x: CGFloat)] = []
                for pt in ungVien {
                    let s = pt.chu.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !s.isEmpty else { continue }
                    if let cuoi = cacCumChuoi.last, pt.x - cuoi.x < 0.065 {
                        cacCumChuoi[cacCumChuoi.count - 1].chuoi += s
                    } else if pt.x >= xMin || s == "-" || s == "–" || s == "−" {
                        cacCumChuoi.append((chuoi: s, x: pt.x))
                    }
                }

                if laCotPhanTram {
                    if let coPct = cacCumChuoi.first(where: { $0.chuoi.contains("%") }),
                       let val = chuyenChuoiThanhSoDoanhThu(coPct.chuoi) {
                        return val
                    }
                } else {
                    if let khongPct = cacCumChuoi.first(where: { !$0.chuoi.contains("%") && chuyenChuoiThanhSoDoanhThu($0.chuoi) != nil }),
                       let val = chuyenChuoiThanhSoDoanhThu(khongPct.chuoi) {
                        return val
                    }
                }

                for cum in cacCumChuoi {
                    if let val = chuyenChuoiThanhSoDoanhThu(cum.chuoi) {
                        return val
                    }
                }
                return nil
            }

            // Chỉ lọc lấy đúng 3 số liệu:
            // 1. Số Lượng (cột ~ 0.30 ..< 0.47)
            // 2. DT QĐ (cột ~ 0.47 ..< 0.65)
            // (Bỏ qua cột DT QĐ Khoản vay ở ~ 0.65 ..< 0.80 và mọi số liệu khác)
            // 3. % tỉ trọng (cột ~ 0.80 ..< 0.995)
            let soLuongOpt = laySoTrongCot(0.30, 0.47, laCotPhanTram: false)
            let doanhThuQDOpt = laySoTrongCot(0.47, 0.65, laCotPhanTram: false)
            let phanTramTyTrongOpt = laySoTrongCot(0.80, 0.995, laCotPhanTram: true)

            guard soLuongOpt != nil || doanhThuQDOpt != nil || phanTramTyTrongOpt != nil else { continue }

            daXetMa.insert(maNV)
            ketQua.append(DoanhThuNhanVienItem(
                maNV: maNV,
                hoTen: hoTen,
                soLuong: soLuongOpt ?? 0,
                doanhThuQD: doanhThuQDOpt ?? 0,
                phanTramTyTrong: phanTramTyTrongOpt ?? 0
            ))
        }

        return ketQua
    }

    private func laChuoiRac(_ chu: String, watermark: String?) -> Bool {
        let inHoa = boDau(chu).trimmingCharacters(in: .whitespacesAndNewlines)
        if inHoa == "TONG" || inHoa == "TARGET" || inHoa.contains("% HT") || inHoa.contains("DU BAO") || inHoa.contains("HANG TRONG") || inHoa.contains("BO PHAN") {
            return true
        }
        if let wm = watermark, inHoa.contains(wm) {
            return true
        }
        return false
    }

    private func timGiaTriSo(trong danhSach: [PhanTuVanBan], watermark: String?) -> Double? {
        let sapXep = danhSach.sorted { $0.y < $1.y }
        for pt in sapXep {
            let chu = pt.chu.trimmingCharacters(in: .whitespacesAndNewlines)
            if let wm = watermark, chu.contains(wm) { continue }
            if let so = chuyenChuoiThanhSo(chu, watermark: watermark) {
                return so
            }
        }
        return nil
    }

    private func chuyenChuoiThanhSo(_ chuoi: String, watermark: String? = nil) -> Double? {
        var sach = chuoi
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "…", with: "")
            .replacingOccurrences(of: "...", with: "")
            .replacingOccurrences(of: "..", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        sach = sach.replacingOccurrences(of: ",", with: "")

        guard !sach.isEmpty else { return nil }
        if sach.range(of: "^-?\\d+(\\.\\d+)?$", options: .regularExpression) != nil {
            if let wm = watermark, sach == wm { return nil }
            return Double(sach)
        }
        if let range = sach.range(of: "-?\\d+(\\.\\d+)?$", options: .regularExpression) {
            let token = String(sach[range])
            if let wm = watermark, token == wm { return nil }
            return Double(token)
        }
        return nil
    }

    // MARK: - Phân tích ảnh chụp màn hình "Doanh thu hợp nhất" (Lũy kế & Realtime: DT thực & DT quy đổi)

    private func boDau(_ chuoi: String) -> String {
        chuoi
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
            .uppercased()
    }

    private func chuyenChuoiThanhSoDoanhThu(_ chuoi: String) -> Double? {
        var s = chuoi
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "%", with: "")
            .replacingOccurrences(of: "…", with: "")
            .replacingOccurrences(of: "...", with: "")
            .replacingOccurrences(of: "+", with: "")
            .replacingOccurrences(of: "^[^0-9\\-]+|[^0-9]+$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !s.isEmpty else { return nil }

        if s.contains(",") && s.contains(".") {
            let viTriPhay = s.lastIndex(of: ",")!
            let viTriCham = s.lastIndex(of: ".")!
            if viTriPhay > viTriCham {
                s = s.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            } else {
                s = s.replacingOccurrences(of: ",", with: "")
            }
        } else if s.contains(",") {
            if s.range(of: "^-?\\d{1,3}(,\\d{3})+$", options: .regularExpression) != nil {
                s = s.replacingOccurrences(of: ",", with: "")
            } else {
                s = s.replacingOccurrences(of: ",", with: ".")
            }
        } else if s.contains(".") {
            if s.range(of: "^-?\\d{1,3}(\\.\\d{3})+$", options: .regularExpression) != nil {
                s = s.replacingOccurrences(of: ".", with: "")
            }
        }

        if let range = s.range(of: "-?\\d+(\\.\\d+)?", options: .regularExpression) {
            return Double(String(s[range]))
        }
        return nil
    }

    private func trichCacSo(trong chuoi: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: "-?\\d+[\\d.,]*") else { return [] }
        let ns = chuoi as NSString
        let matches = regex.matches(in: chuoi, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { m in
            let sub = ns.substring(with: m.range)
            return chuyenChuoiThanhSoDoanhThu(sub)
        }
    }

    private func phanTichDoanhThu(phanTu: [PhanTuVanBan]) -> ThongTinDoanhThu {
        var kq = ThongTinDoanhThu()

        // 1. Tìm thanh "Quỹ thời gian: 30/31 ngày" (Lũy kế) hoặc "THỜI GIAN LÀM VIỆC: 08:00 - 22:00" (Realtime)
        var yBatDauVungThe: CGFloat = 0.44
        if let mocQTG = phanTu.first(where: {
            let u = boDau($0.chu)
            return u.contains("QUY THOI GIAN") || u.contains("TIEN DO THANG") || u.contains("THOI GIAN LAM VIEC")
        }) {
            yBatDauVungThe = mocQTG.y + 0.02
            let cungHang = phanTu
                .filter { abs($0.y - mocQTG.y) < 0.035 }
                .sorted { $0.x < $1.x }
            let chuoiHang = cungHang.map { $0.chu }.joined(separator: " ")

            if !boDau(chuoiHang).contains("LAM VIEC"),
               let regex = try? NSRegularExpression(pattern: "(\\d{1,2})\\s*/\\s*(\\d{1,2})"),
               let m = regex.firstMatch(in: chuoiHang, range: NSRange(location: 0, length: (chuoiHang as NSString).length)) {
                let ns = chuoiHang as NSString
                let d1 = Int(ns.substring(with: m.range(at: 1))) ?? 0
                let d2 = Int(ns.substring(with: m.range(at: 2))) ?? 0
                if d1 > 0 && d2 > 0 {
                    kq.soNgayDaQua = d1
                    kq.tongSoNgay = d2
                }
            }
            if let ptPhanTram = cungHang.last(where: { $0.chu.contains("%") }),
               let val = chuyenChuoiThanhSoDoanhThu(ptPhanTram.chu) {
                kq.phanTramTienDoThang = val
            } else if kq.soNgayDaQua > 0 && kq.tongSoNgay > 0 {
                kq.phanTramTienDoThang = (Double(kq.soNgayDaQua) / Double(kq.tongSoNgay)) * 100.0
            }
        } else if let mocNut = phanTu.filter({
            let u = boDau($0.chu)
            return u.contains("XUAT EXCEL") || u.contains("XUAT THEO MAU") || u.contains("TOAN CONG TY")
        }).max(by: { $0.y < $1.y }) {
            yBatDauVungThe = mocNut.y + 0.03
        }

        // 2. Lọc vùng các thẻ chỉ số bên dưới thanh Quỹ thời gian / Thời gian làm việc (tới sát thanh tab đáy y < 0.965)
        let vungThe = phanTu.filter { pt in
            guard pt.y > yBatDauVungThe && pt.y < 0.965 else { return false }
            if pt.y > 0.935 {
                let u = boDau(pt.chu)
                if u == "DOANH THU" || u.contains("TONG HOP") || u.contains("NGANH HANG BI") {
                    return false
                }
            }
            return true
        }

        let laAnhQuyDoi = vungThe.contains { pt in
            let u = boDau(pt.chu)
            return u.contains("DT QUY DOI") || u.contains("KHOAN VAY") || u.contains("TRA GOP QD")
        }

        func layDuLieuThe(thoaMan: (String) -> Bool) -> (soChinh: Double?, vanBanPhu: String)? {
            guard let moc = vungThe.sorted(by: { $0.y < $1.y }).first(where: { thoaMan(boDau($0.chu)) }) else {
                return nil
            }
            let laCotTrai = moc.x < 0.47
            let trongThe = vungThe.filter { pt in
                let cungCot = laCotTrai ? (pt.x < 0.47) : (pt.x >= 0.47)
                return cungCot && pt.y > moc.y + 0.008 && pt.y < moc.y + 0.12
            }.sorted {
                if abs($0.y - $1.y) < 0.012 { return $0.x < $1.x }
                return $0.y < $1.y
            }

            var soChinh: Double?
            for pt in trongThe where pt.y < moc.y + 0.072 {
                let u = boDau(pt.chu).trimmingCharacters(in: .whitespacesAndNewlines)
                if u == "?" || u.contains("TRIEU DONG") || u.contains("TARGET") || u.contains("BILL") || u.contains("TRA GOP") || u.contains("CHUA CO") {
                    continue
                }
                if let val = chuyenChuoiThanhSoDoanhThu(pt.chu) {
                    soChinh = val
                    break
                }
            }
            let vanBanPhu = trongThe.map { $0.chu }.joined(separator: " ")
            return (soChinh, vanBanPhu)
        }

        // 3A. Ô "DT thực"
        if !laAnhQuyDoi, let theDTThuc = layDuLieuThe(thoaMan: { $0 == "DT THUC" || ($0.contains("DT THUC") && !$0.contains("LUY KE")) }) {
            if let so = theDTThuc.soChinh { kq.doanhThuThuc = so }
        }

        // 3B. Ô "DT quy đổi"
        if laAnhQuyDoi, let theDTQD = layDuLieuThe(thoaMan: { $0 == "DT QUY DOI" || ($0.contains("DT QUY DOI") && !$0.contains("KHOAN VAY")) }) {
            if let so = theDTQD.soChinh { kq.doanhThuQuyDoi = so }
        }

        // 3C. Ô "DT dự kiến"
        if let theDuKien = layDuLieuThe(thoaMan: { $0.contains("DT DU KIEN") || $0 == "DU KIEN" }) {
            if let so = theDuKien.soChinh {
                if laAnhQuyDoi {
                    kq.duKienQuyDoi = so
                } else {
                    kq.duKienThuc = so
                }
            }
        }

        // 3D. Ô "% HT target" / "% HT dự kiến" / "% HT target ngày"
        if let theHT = layDuLieuThe(thoaMan: { $0.contains("HT TARGET") || $0.contains("HT DU KIEN") || $0.contains("DU KIEN HOAN") || ($0.contains("TARGET") && $0.contains("%")) }) {
            if let so = theHT.soChinh {
                if laAnhQuyDoi {
                    kq.phanTramHTQuyDoi = so
                } else {
                    kq.phanTramHTThuc = so
                }
            }
            let phuKhongDau = boDau(theHT.vanBanPhu)
            if let range = phuKhongDau.range(of: "KY\\s*([0-9][0-9.,]*)", options: .regularExpression) ??
                phuKhongDau.range(of: "TARGET[^0-9]*([0-9][0-9.,]*)", options: .regularExpression) {
                let chuoiCon = String(phuKhongDau[range])
                if let targetVal = trichCacSo(trong: chuoiCon).first, targetVal > 0 {
                    if laAnhQuyDoi {
                        kq.targetQuyDoi = targetVal
                    } else {
                        kq.targetThuc = targetVal
                    }
                }
            }
        }

        // 3E. Ô "TT vs TB 3 tháng"
        if let theTB3T = layDuLieuThe(thoaMan: { $0.contains("TB 3 THANG") || $0.contains("TT VS") }) {
            if let so = theTB3T.soChinh {
                kq.tangGiamCungKy = so
                kq.coTangGiam = true
            }
            let phuKhongDau = boDau(theTB3T.vanBanPhu)
            if let range = phuKhongDau.range(of: "SO:?\\s*([0-9][0-9.,]*)", options: .regularExpression) ??
                phuKhongDau.range(of: "CUA[^0-9]*([0-9][0-9.,]*)", options: .regularExpression) {
                let chuoiCon = String(phuKhongDau[range])
                if let tbVal = trichCacSo(trong: chuoiCon).last, tbVal > 0 {
                    kq.tb3Thang = tbVal
                }
            }
        }

        // 3F. Ô "TLPVTC lũy kế" / "TLPVTC hôm nay" -> Lấy % PVTC, Số Bill và Lượt Khách
        if let thePVTC = layDuLieuThe(thoaMan: { $0.contains("TLPVTC") || $0.contains("PVTC") }) {
            if let so = thePVTC.soChinh {
                kq.phanTramPVTC = so
            }
            let phuKhongDau = boDau(thePVTC.vanBanPhu)
            if let rBill = phuKhongDau.range(of: "([0-9][0-9.,]*)\\s*BILL", options: .regularExpression) {
                if let bVal = trichCacSo(trong: String(phuKhongDau[rBill])).first {
                    kq.soBill = bVal
                }
            }
            if let rKhach = phuKhongDau.range(of: "([0-9][0-9.,]*)\\s*KHACH", options: .regularExpression) {
                if let kVal = trichCacSo(trong: String(phuKhongDau[rKhach])).first {
                    kq.luotKhach = kVal
                }
            }
        }

        // 3G. Ô "Tỷ trọng trả chậm"
        if let theTraCham = layDuLieuThe(thoaMan: { $0.contains("TRA CHAM") || $0.contains("TY TRONG") }) {
            if let so = theTraCham.soChinh {
                kq.phanTramTraGop = so
            }
            let phuKhongDau = boDau(theTraCham.vanBanPhu)
            if let rTG = phuKhongDau.range(of: "TRA GOP(?:\\s*QD)?\\s*([0-9][0-9.,]*)", options: .regularExpression) {
                if let tgVal = trichCacSo(trong: String(phuKhongDau[rTG])).first {
                    kq.doanhThuTraGop = tgVal
                }
            }
        }

        // 4. Dự phòng nếu người dùng quét ảnh đã tổng hợp sẵn kiểu Ảnh 3
        if !kq.coDuLieu {
            if let mocThuc = phanTu.first(where: { boDau($0.chu).contains("DOANH THU THUC") }),
               let mocQD = phanTu.first(where: { boDau($0.chu).contains("DOANH THU QD") }) {
                let ranhX = (mocThuc.x + mocQD.x) / 2.0
                let vung = phanTu.filter { $0.y > min(mocThuc.y, mocQD.y) && $0.y < min(mocThuc.y, mocQD.y) + 0.18 }
                let trai = vung.filter { $0.x < ranhX }.sorted { $0.y < $1.y }
                let phai = vung.filter { $0.x >= ranhX }.sorted { $0.y < $1.y }
                for pt in trai {
                    if boDau(pt.chu).contains("TARGET"), let v = trichCacSo(trong: pt.chu).first { kq.targetThuc = v }
                    else if kq.doanhThuThuc == 0, let v = chuyenChuoiThanhSoDoanhThu(pt.chu), v > 0 { kq.doanhThuThuc = v }
                }
                for pt in phai {
                    if boDau(pt.chu).contains("TARGET"), let v = trichCacSo(trong: pt.chu).first { kq.targetQuyDoi = v }
                    else if kq.doanhThuQuyDoi == 0, let v = chuyenChuoiThanhSoDoanhThu(pt.chu), v > 0 { kq.doanhThuQuyDoi = v }
                }
            }
        }

        return kq
    }
}

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
