import UIKit

enum LoaiCheDoDoanhThu: Int, CaseIterable {
    case luyKe = 0
    case realtime = 1

    var tieuDe: String {
        switch self {
        case .luyKe: return "Lũy kế"
        case .realtime: return "Realtime"
        }
    }
}

enum LoaiTabMuc: Int, CaseIterable {
    case thiDua = 0
    case nhanVien = 1
    case duPhong2 = 2

    /// Danh sách 2 nút ở cụm dưới (đã xoá nút Dự phòng 3 theo yêu cầu)
    static let cacTabCumDuoi: [LoaiTabMuc] = [.thiDua, .nhanVien]

    var tieuDe: String {
        switch self {
        case .thiDua: return "Thi đua"
        case .nhanVien: return "Nhân viên"
        case .duPhong2: return "Biểu đồ"
        }
    }
}

enum KieuSapXepNhanVien: Int, CaseIterable {
    case soMonHoanThanh = 0
    case doanhThuQD = 1
    case phanTramTB = 2

    var nhan: String {
        switch self {
        case .soMonHoanThanh: return "🏆 Số môn hoàn thành (Cao → Thấp)"
        case .doanhThuQD: return "🎯 Doanh thu QĐ (Cao → Thấp)"
        case .phanTramTB: return "📈 % HT thi đua TB (Cao → Thấp)"
        }
    }

    var nhanNgan: String {
        switch self {
        case .soMonHoanThanh: return "Số môn HT"
        case .doanhThuQD: return "DT QĐ"
        case .phanTramTB: return "% HT TB"
        }
    }
}

struct NhanVienQuanLy: Codable, Hashable, Identifiable {
    var maNV: String
    var hoTen: String
    var id: String { maNV }
}

struct DoanhThuNhanVienItem: Codable, Hashable {
    var maNV: String
    var hoTen: String
    var soLuong: Double = 0
    var doanhThuQD: Double = 0
    var phanTramTyTrong: Double = 0

    enum CodingKeys: String, CodingKey {
        case maNV
        case hoTen
        case soLuong
        case doanhThuQD
        case phanTramTyTrong
        case dtTraThangQD
    }

    init(
        maNV: String,
        hoTen: String,
        soLuong: Double = 0,
        doanhThuQD: Double = 0,
        phanTramTyTrong: Double = 0
    ) {
        self.maNV = maNV
        self.hoTen = hoTen
        self.soLuong = soLuong
        self.doanhThuQD = doanhThuQD
        self.phanTramTyTrong = phanTramTyTrong
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        maNV = (try? c.decode(String.self, forKey: .maNV)) ?? ""
        hoTen = (try? c.decode(String.self, forKey: .hoTen)) ?? ""
        soLuong = (try? c.decode(Double.self, forKey: .soLuong)) ?? 0
        doanhThuQD = (try? c.decode(Double.self, forKey: .doanhThuQD)) ?? 0
        if let tyTrong = try? c.decode(Double.self, forKey: .phanTramTyTrong) {
            phanTramTyTrong = tyTrong
        } else {
            phanTramTyTrong = (try? c.decode(Double.self, forKey: .dtTraThangQD)) ?? 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(maNV, forKey: .maNV)
        try c.encode(hoTen, forKey: .hoTen)
        try c.encode(soLuong, forKey: .soLuong)
        try c.encode(doanhThuQD, forKey: .doanhThuQD)
        try c.encode(phanTramTyTrong, forKey: .phanTramTyTrong)
    }
}

struct DongXepHangNhanVienNganh: Hashable {
    var maNV: String
    var hoTen: String
    var thucHien: Double
    var targetCaNhan: Double
    var phanTramHT: Double
    var chenhLech: Double { thucHien - targetCaNhan }
    var daDat: Bool { phanTramHT >= 99.995 }
}

struct MonThiDuaNhanVien: Hashable {
    var khoaNganh: String
    var tenNganhHang: String
    var loaiChiTieu: LoaiChiTieuThiDua
    var thucHien: Double
    var targetCaNhan: Double
    var phanTramHT: Double
    var phanTramSieuThi: Double
    var conLai: Double { targetCaNhan - thucHien }
    var daDat: Bool { phanTramHT >= 99.995 }
}

struct TongHopNhanVien: Hashable {
    var nhanVien: NhanVienQuanLy
    var soMonDat: Int
    var tongMonGiao: Int
    var phanTramHTTB: Double
    var doanhThuQD: Double
    var soLuongDon: Double
    var phanTramTyTrong: Double
    var cacMonGiao: [MonThiDuaNhanVien]
    var doanhThuCaNhan: DoanhThuNhanVienItem?

    var coDoanhThuCaNhan: Bool {
        doanhThuCaNhan != nil
    }
}

enum LoaiBieuDoThang: Int, CaseIterable {
    case realtime = 0
    case sucKhoeNhanVien = 1

    var tieuDe: String {
        switch self {
        case .realtime: return "📊 Biểu đồ Realtime"
        case .sucKhoeNhanVien: return "❤️‍🩹 Biểu đồ sức khỏe NV"
        }
    }
}

enum MucDoSucKhoeNV: Int, Codable, Hashable {
    case khoe = 0
    case trungBinh = 1
    case yeu = 2
    case chuaCoSo = 3

    var nhan: String {
        switch self {
        case .khoe: return "Khỏe mạnh"
        case .trungBinh: return "Trung bình"
        case .yeu: return "Yếu"
        case .chuaCoSo: return "Chưa có số"
        }
    }

    var kyHieu: String {
        switch self {
        case .khoe: return "🟢"
        case .trungBinh: return "🟡"
        case .yeu: return "🔴"
        case .chuaCoSo: return "⚪"
        }
    }
}

struct DiemSucKhoeNgayNV: Hashable {
    var khoaNgay: String
    var ngayTrongThang: Int
    var nhanNgay: String
    var diemSucKhoe: Double
    var mucDo: MucDoSucKhoeNV
    var soMonDat: Int
    var tongMonGiao: Int
    var phanTramHTTB: Double
    var doanhThuQD: Double
}

struct HoSoSucKhoeNhanVien: Hashable {
    var nhanVien: NhanVienQuanLy
    var tongHopHienTai: TongHopNhanVien
    var diemSucKhoe: Double
    var mucDo: MucDoSucKhoeNV
    var soNgayYeuLienTuc: Int
    var chuoiYeuDaiNhat: Int
    var tongSoNgayYeu: Int
    var tongSoNgayCoSo: Int
    var lichSuNgay: [DiemSucKhoeNgayNV]
    var cacMonYeuNhat: [String]
    var xuHuongDiem: Double
    var laCanhBaoTop5: Bool
    var hangCanhBao: Int?

    var nhanXuHuong: String {
        if xuHuongDiem >= 3.0 { return "📈 Tăng" }
        if xuHuongDiem <= -3.0 { return "📉 Giảm" }
        return "➖ Đi ngang"
    }

    var chuoiCanhBaoYeu: String {
        if soNgayYeuLienTuc >= 2 {
            return "🔥 Yếu \(soNgayYeuLienTuc) ngày liên tục"
        } else if soNgayYeuLienTuc == 1 {
            return "⚠️ Yếu \(tongSoNgayYeu > 1 ? "\(tongSoNgayYeu) ngày (đang yếu)" : "1 ngày gần nhất")"
        } else if tongSoNgayYeu > 0 {
            return "⚠️ Đã yếu \(tongSoNgayYeu)/\(max(1, tongSoNgayCoSo)) ngày"
        } else {
            return "⚠️ Điểm SK thấp (\(Int(round(diemSucKhoe)))%)"
        }
    }
}

struct BaoCaoSucKhoeDoiNgu: Hashable {
    var ngayBaoCao: Date
    var cheDo: LoaiCheDoDoanhThu
    var soNgayDaTheoDoi: Int
    var cacNhanNgayTheoDoi: [String]
    var soNVKhoe: Int
    var soNVTrungBinh: Int
    var soNVYeu: Int
    var diemTrungBinhDoiNgu: Double
    var top5CanhBaoYeu: [HoSoSucKhoeNhanVien]
    var danhSachTatCa: [HoSoSucKhoeNhanVien]
}

enum KieuHienThiBaoCao: Int, Codable, CaseIterable {
    case bangChiTiet = 0
    case theGon = 1

    var tieuDe: String {
        switch self {
        case .bangChiTiet: return "Bảng 8 cột"
        case .theGon: return "Thẻ tiến độ"
        }
    }

    var maWeb: String {
        switch self {
        case .bangChiTiet: return "bangChiTiet"
        case .theGon: return "theGon"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let rawInt = try? container.decode(Int.self), let val = KieuHienThiBaoCao(rawValue: rawInt) {
            self = val
        } else if let rawStr = try? container.decode(String.self) {
            self = (rawStr == "theGon") ? .theGon : .bangChiTiet
        } else {
            self = .bangChiTiet
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(maWeb)
    }
}

enum LoaiChiTieuThiDua: String, Codable, CaseIterable {
    case soLuong = "SL"
    case doanhThu = "DT"

    var maBang: String {
        switch self {
        case .soLuong: return "SL"
        case .doanhThu: return "DT"
        }
    }

    var maThe: String {
        switch self {
        case .soLuong: return "SLLK"
        case .doanhThu: return "DTLK"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.uppercased() ?? "DT"
        if raw.contains("SL") {
            self = .soLuong
        } else {
            self = .doanhThu
        }
    }
}

struct ThongTinDoanhThu: Codable, Hashable {
    var doanhThuThuc: Double = 0
    var targetThuc: Double = 0
    var duKienThuc: Double = 0
    var phanTramHTThuc: Double = 0

    var doanhThuQuyDoi: Double = 0
    var targetQuyDoi: Double = 0
    var duKienQuyDoi: Double = 0
    var phanTramHTQuyDoi: Double = 0

    var phanTramTraGop: Double = 0
    var doanhThuTraGop: Double = 0

    var luotKhach: Double = 0
    var soBill: Double = 0
    var phanTramPVTC: Double = 0

    var tangGiamCungKy: Double = 0
    var coTangGiam: Bool = false
    var tb3Thang: Double = 0

    var soNgayDaQua: Int = 0
    var tongSoNgay: Int = 0
    var phanTramTienDoThang: Double = 0

    init(
        doanhThuThuc: Double = 0,
        targetThuc: Double = 0,
        duKienThuc: Double = 0,
        phanTramHTThuc: Double = 0,
        doanhThuQuyDoi: Double = 0,
        targetQuyDoi: Double = 0,
        duKienQuyDoi: Double = 0,
        phanTramHTQuyDoi: Double = 0,
        phanTramTraGop: Double = 0,
        doanhThuTraGop: Double = 0,
        luotKhach: Double = 0,
        soBill: Double = 0,
        phanTramPVTC: Double = 0,
        tangGiamCungKy: Double = 0,
        coTangGiam: Bool = false,
        tb3Thang: Double = 0,
        soNgayDaQua: Int = 0,
        tongSoNgay: Int = 0,
        phanTramTienDoThang: Double = 0
    ) {
        self.doanhThuThuc = doanhThuThuc
        self.targetThuc = targetThuc
        self.duKienThuc = duKienThuc
        self.phanTramHTThuc = phanTramHTThuc
        self.doanhThuQuyDoi = doanhThuQuyDoi
        self.targetQuyDoi = targetQuyDoi
        self.duKienQuyDoi = duKienQuyDoi
        self.phanTramHTQuyDoi = phanTramHTQuyDoi
        self.phanTramTraGop = phanTramTraGop
        self.doanhThuTraGop = doanhThuTraGop
        self.luotKhach = luotKhach
        self.soBill = soBill
        self.phanTramPVTC = phanTramPVTC
        self.tangGiamCungKy = tangGiamCungKy
        self.coTangGiam = coTangGiam
        self.tb3Thang = tb3Thang
        self.soNgayDaQua = soNgayDaQua
        self.tongSoNgay = tongSoNgay
        self.phanTramTienDoThang = phanTramTienDoThang
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        doanhThuThuc = (try? c.decode(Double.self, forKey: .doanhThuThuc)) ?? 0
        targetThuc = (try? c.decode(Double.self, forKey: .targetThuc)) ?? 0
        duKienThuc = (try? c.decode(Double.self, forKey: .duKienThuc)) ?? 0
        phanTramHTThuc = (try? c.decode(Double.self, forKey: .phanTramHTThuc)) ?? 0
        doanhThuQuyDoi = (try? c.decode(Double.self, forKey: .doanhThuQuyDoi)) ?? 0
        targetQuyDoi = (try? c.decode(Double.self, forKey: .targetQuyDoi)) ?? 0
        duKienQuyDoi = (try? c.decode(Double.self, forKey: .duKienQuyDoi)) ?? 0
        phanTramHTQuyDoi = (try? c.decode(Double.self, forKey: .phanTramHTQuyDoi)) ?? 0
        phanTramTraGop = (try? c.decode(Double.self, forKey: .phanTramTraGop)) ?? 0
        doanhThuTraGop = (try? c.decode(Double.self, forKey: .doanhThuTraGop)) ?? 0
        luotKhach = (try? c.decode(Double.self, forKey: .luotKhach)) ?? 0
        soBill = (try? c.decode(Double.self, forKey: .soBill)) ?? 0
        phanTramPVTC = (try? c.decode(Double.self, forKey: .phanTramPVTC)) ?? 0
        tangGiamCungKy = (try? c.decode(Double.self, forKey: .tangGiamCungKy)) ?? 0
        coTangGiam = (try? c.decode(Bool.self, forKey: .coTangGiam)) ?? (tangGiamCungKy != 0)
        tb3Thang = (try? c.decode(Double.self, forKey: .tb3Thang)) ?? 0
        soNgayDaQua = (try? c.decode(Int.self, forKey: .soNgayDaQua)) ?? 0
        tongSoNgay = (try? c.decode(Int.self, forKey: .tongSoNgay)) ?? 0
        phanTramTienDoThang = (try? c.decode(Double.self, forKey: .phanTramTienDoThang)) ?? 0
    }

    var coDuLieu: Bool {
        doanhThuThuc > 0 || targetThuc > 0 || doanhThuQuyDoi > 0 || targetQuyDoi > 0 || luotKhach > 0 || phanTramTraGop > 0
    }

    /// % Quy đổi = (DT Quy đổi - DT Thực) / DT Thực * 100
    var phanTramQuyDoi: Double {
        guard doanhThuThuc > 0, doanhThuQuyDoi > 0 else { return 0 }
        return ((doanhThuQuyDoi - doanhThuThuc) / doanhThuThuc) * 100.0
    }

    /// % Hoàn thành Doanh thu thực
    var phanTramHTThucHienThi: Double {
        if phanTramHTThuc > 0 { return phanTramHTThuc }
        if targetThuc > 0, doanhThuThuc > 0 {
            return (doanhThuThuc / targetThuc) * 100.0
        }
        return 0
    }

    /// % Hoàn thành QĐ dự kiến (hiển thị trực tiếp con số quét được từ ảnh)
    var phanTramHTQDDuKienHienThi: Double {
        if phanTramHTQuyDoi > 0 { return phanTramHTQuyDoi }
        if duKienQuyDoi > 0, targetQuyDoi > 0 {
            return (duKienQuyDoi / targetQuyDoi) * 100.0
        }
        if targetQuyDoi > 0, doanhThuQuyDoi > 0 {
            return (doanhThuQuyDoi / targetQuyDoi) * 100.0
        }
        if phanTramHTThuc > 0 { return phanTramHTThuc }
        if targetThuc > 0, doanhThuThuc > 0 {
            return (doanhThuThuc / targetThuc) * 100.0
        }
        return 0
    }

    /// Gộp dữ liệu từ ảnh mới quét (ví dụ quét ảnh DT thực rồi quét tiếp ảnh DT quy đổi)
    func gop(voi moi: ThongTinDoanhThu, laRealtime: Bool = false) -> ThongTinDoanhThu {
        var kq = self
        if moi.doanhThuThuc > 0 { kq.doanhThuThuc = moi.doanhThuThuc }
        if moi.targetThuc > 0 { kq.targetThuc = moi.targetThuc }
        if moi.duKienThuc > 0 { kq.duKienThuc = moi.duKienThuc }
        if moi.phanTramHTThuc > 0 { kq.phanTramHTThuc = moi.phanTramHTThuc }

        if moi.doanhThuQuyDoi > 0 { kq.doanhThuQuyDoi = moi.doanhThuQuyDoi }
        if moi.targetQuyDoi > 0 { kq.targetQuyDoi = moi.targetQuyDoi }
        if moi.duKienQuyDoi > 0 { kq.duKienQuyDoi = moi.duKienQuyDoi }
        if moi.phanTramHTQuyDoi > 0 { kq.phanTramHTQuyDoi = moi.phanTramHTQuyDoi }

        if moi.phanTramTraGop > 0 { kq.phanTramTraGop = moi.phanTramTraGop }
        if moi.doanhThuTraGop > 0 { kq.doanhThuTraGop = moi.doanhThuTraGop }

        if moi.luotKhach > 0 { kq.luotKhach = moi.luotKhach }
        if moi.soBill > 0 { kq.soBill = moi.soBill }
        if moi.phanTramPVTC > 0 { kq.phanTramPVTC = moi.phanTramPVTC }

        if moi.coTangGiam || moi.tangGiamCungKy != 0 {
            kq.tangGiamCungKy = moi.tangGiamCungKy
            kq.coTangGiam = true
        }
        if moi.tb3Thang > 0 { kq.tb3Thang = moi.tb3Thang }

        if moi.soNgayDaQua > 0 { kq.soNgayDaQua = moi.soNgayDaQua }
        if moi.tongSoNgay > 0 { kq.tongSoNgay = moi.tongSoNgay }
        if moi.phanTramTienDoThang > 0 { kq.phanTramTienDoThang = moi.phanTramTienDoThang }
        return kq
    }
}

struct DongThiDua: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var tenNganhHangGoc: String
    var tenNganhHang: String
    var loaiChiTieu: LoaiChiTieuThiDua
    var thucHien: Double
    var target: Double
    var phanTramHTGoc: Double?
    var phanTramDuBaoGoc: Double?
    var duKienGoc: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case tenNganhHangGoc
        case tenNganhHang
        case loaiChiTieu
        case thucHien
        case target
        case phanTramHTGoc
        case phanTramDuBaoGoc
        case duKienGoc
    }

    init(
        id: UUID = UUID(),
        tenNganhHangGoc: String? = nil,
        tenNganhHang: String,
        loaiChiTieu: LoaiChiTieuThiDua,
        thucHien: Double,
        target: Double,
        phanTramHTGoc: Double? = nil,
        phanTramDuBaoGoc: Double? = nil,
        duKienGoc: Double? = nil
    ) {
        self.id = id
        let goc = tenNganhHangGoc ?? tenNganhHang
        self.tenNganhHangGoc = goc
        self.tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
        self.loaiChiTieu = loaiChiTieu
        self.thucHien = thucHien
        self.target = target
        self.phanTramHTGoc = phanTramHTGoc
        self.phanTramDuBaoGoc = phanTramDuBaoGoc
        self.duKienGoc = duKienGoc
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let uuid = try? c.decode(UUID.self, forKey: .id) {
            id = uuid
        } else if let str = try? c.decode(String.self, forKey: .id), let uuid = UUID(uuidString: str) {
            id = uuid
        } else {
            id = UUID()
        }
        let ten = (try? c.decode(String.self, forKey: .tenNganhHang)) ?? ""
        let goc = (try? c.decode(String.self, forKey: .tenNganhHangGoc)) ?? ten
        tenNganhHangGoc = goc
        tenNganhHang = ten.isEmpty ? goc : ten
        loaiChiTieu = (try? c.decode(LoaiChiTieuThiDua.self, forKey: .loaiChiTieu)) ?? .doanhThu
        thucHien = (try? c.decode(Double.self, forKey: .thucHien)) ?? 0
        target = (try? c.decode(Double.self, forKey: .target)) ?? 0
        phanTramHTGoc = try? c.decode(Double.self, forKey: .phanTramHTGoc)
        phanTramDuBaoGoc = try? c.decode(Double.self, forKey: .phanTramDuBaoGoc)
        duKienGoc = try? c.decode(Double.self, forKey: .duKienGoc)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id.uuidString.lowercased(), forKey: .id)
        try c.encode(tenNganhHangGoc, forKey: .tenNganhHangGoc)
        try c.encode(tenNganhHang, forKey: .tenNganhHang)
        try c.encode(loaiChiTieu, forKey: .loaiChiTieu)
        try c.encode(thucHien, forKey: .thucHien)
        try c.encode(target, forKey: .target)
        try c.encodeIfPresent(phanTramHTGoc, forKey: .phanTramHTGoc)
        try c.encodeIfPresent(phanTramDuBaoGoc, forKey: .phanTramDuBaoGoc)
        try c.encodeIfPresent(duKienGoc, forKey: .duKienGoc)
    }

    var chenhLech: Double {
        thucHien - target
    }

    var conThieu: Double {
        max(0, target - thucHien)
    }

    var vuotMuc: Double {
        max(0, thucHien - target)
    }

    var phanTramHT: Double {
        if target > 0.0001 {
            let htTinh = (thucHien / target) * 100.0
            if let goc = phanTramHTGoc, goc > 0, abs(htTinh - goc) <= 1.2 {
                return goc
            }
            return htTinh
        }
        return phanTramHTGoc ?? 0
    }

    /// Doanh thu / Số lượng dự kiến cuối tháng (ưu tiên con số quét trực tiếp từ ô DT DỰ KIẾN / SL DỰ KIẾN trên ảnh Lũy kế)
    var duKien: Double {
        if let dk = duKienGoc, dk > 0 {
            if let htGoc = phanTramHTGoc, htGoc > 0.1, target > 0.0001 {
                let htMoi = (thucHien / target) * 100.0
                if abs(htMoi - htGoc) > 1.5 {
                    let uoc = (target * phanTramDuBao) / 100.0
                    return loaiChiTieu == .soLuong ? uoc.rounded() : ((uoc * 100).rounded() / 100)
                }
            }
            return dk
        }
        if target > 0.0001, phanTramDuBao > 0 {
            let uoc = (target * phanTramDuBao) / 100.0
            return loaiChiTieu == .soLuong ? uoc.rounded() : ((uoc * 100).rounded() / 100)
        }
        let uoc = thucHien * TienIchNgay.heSoDuBaoThang()
        return loaiChiTieu == .soLuong ? uoc.rounded() : ((uoc * 100).rounded() / 100)
    }

    var chenhLechDuKien: Double {
        duKien - target
    }

    var conThieuDuKien: Double {
        max(0, target - duKien)
    }

    var vuotMucDuKien: Double {
        max(0, duKien - target)
    }

    var phanTramDuBao: Double {
        if let goc = phanTramDuBaoGoc, goc > 0 {
            if let htGoc = phanTramHTGoc, htGoc > 0.1, target > 0.0001 {
                let htMoi = (thucHien / target) * 100.0
                if abs(htMoi - htGoc) > 1.5 {
                    let tyLe = goc / htGoc
                    return htMoi * tyLe
                }
            }
            return goc
        }
        if let dk = duKienGoc, dk > 0, target > 0.0001 {
            return (dk / target) * 100.0
        }
        return phanTramHT * TienIchNgay.heSoDuBaoThang()
    }

    var daDat: Bool {
        phanTramHT >= 99.995
    }

    var daHoanThanhDuBao: Bool {
        phanTramDuBao >= 99.995
    }
}

struct CaiDatDMX: Codable {
    var kieuHienThi: KieuHienThiBaoCao = .bangChiTiet
    var danhSachCumTuLocBo: [String] = []
    var soCotXuatAnh: Int = 3
    var danhSachNhanVien: [NhanVienQuanLy] = CaiDatDMX.nhanVienMau
    var chiaTargetNganhHang: [String: [String]] = [:]
    var mucTieuDoanhThuQDThang: [String: Double] = [:]

    static let nhanVienMau: [NhanVienQuanLy] = [
        .init(maNV: "24939", hoTen: "Phan Hoàng Sơn"),
        .init(maNV: "201962", hoTen: "Nguyễn Thị Kim Loan"),
        .init(maNV: "261423", hoTen: "Trần Nam Tùng"),
        .init(maNV: "23986", hoTen: "Nguyễn Ngọc Đẩu"),
        .init(maNV: "65255", hoTen: "Nguyễn Thị Thu Thảo"),
        .init(maNV: "285688", hoTen: "Lê Tuấn"),
        .init(maNV: "116719", hoTen: "Đinh Thị Quỳnh Nga"),
        .init(maNV: "186532", hoTen: "Đỗ Thị Mỹ Linh"),
        .init(maNV: "207241", hoTen: "Huỳnh Tấn Thành"),
        .init(maNV: "194649", hoTen: "Nguyễn Hoàn Điện"),
        .init(maNV: "34922", hoTen: "Đỗ Thị Chanh"),
        .init(maNV: "293044", hoTen: "Võ Ngọc Vĩ"),
        .init(maNV: "285681", hoTen: "Hồ Ngọc Châu Ánh"),
        .init(maNV: "280417", hoTen: "Huỳnh Thành Đạt"),
        .init(maNV: "39665", hoTen: "Nguyễn Hữu Kha"),
        .init(maNV: "23997", hoTen: "Lê Thị Kim Phượng")
    ]

    init(
        kieuHienThi: KieuHienThiBaoCao = .bangChiTiet,
        danhSachCumTuLocBo: [String] = [],
        soCotXuatAnh: Int = 3,
        danhSachNhanVien: [NhanVienQuanLy] = CaiDatDMX.nhanVienMau,
        chiaTargetNganhHang: [String: [String]] = [:],
        mucTieuDoanhThuQDThang: [String: Double] = [:]
    ) {
        self.kieuHienThi = kieuHienThi
        self.danhSachCumTuLocBo = danhSachCumTuLocBo
        self.soCotXuatAnh = soCotXuatAnh
        self.danhSachNhanVien = danhSachNhanVien
        self.chiaTargetNganhHang = chiaTargetNganhHang
        self.mucTieuDoanhThuQDThang = mucTieuDoanhThuQDThang
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kieuHienThi = (try? c.decode(KieuHienThiBaoCao.self, forKey: .kieuHienThi)) ?? .bangChiTiet
        danhSachCumTuLocBo = (try? c.decode([String].self, forKey: .danhSachCumTuLocBo)) ?? []
        let cot = (try? c.decode(Int.self, forKey: .soCotXuatAnh)) ?? 3
        soCotXuatAnh = (cot >= 1 && cot <= 4) ? cot : 3
        let dsNV = (try? c.decode([NhanVienQuanLy].self, forKey: .danhSachNhanVien)) ?? []
        danhSachNhanVien = dsNV.isEmpty ? Self.nhanVienMau : dsNV
        chiaTargetNganhHang = (try? c.decode([String: [String]].self, forKey: .chiaTargetNganhHang)) ?? [:]
        mucTieuDoanhThuQDThang = (try? c.decode([String: Double].self, forKey: .mucTieuDoanhThuQDThang)) ?? [:]
    }
}

struct DuBaoQuyDoiThang: Hashable {
    var mucTieuThang: Double
    var soNgayTrongThang: Int
    var mucTieuMoiNgay: Double
    var soNgayCoRealtime: Int
    var tongDTThucRealtime: Double
    var tongDTQDRealtime: Double
    var trungBinhThucMoiNgay: Double
    var trungBinhQDMoiNgay: Double
    var duKienThucCuoiThang: Double
    var duKienQDCuoiThang: Double
    var phanTramHTQDDuKien: Double
    var phanTramQuyDoiDuKien: Double
    var chenhLechDuKienCuoiThang: Double { duKienQDCuoiThang - mucTieuThang }
    var daHoanThanhDuKien: Bool { phanTramHTQDDuKien >= 99.995 }
}

struct DuLieuRealtimeNgayTrongThang: Hashable {
    var ngay: Date
    var khoaNgay: String
    var ngayTrongThang: Int
    var doanhThu: ThongTinDoanhThu

    var doanhThuThuc: Double { doanhThu.doanhThuThuc }
    var targetThuc: Double { doanhThu.targetThuc }
    var doanhThuQuyDoi: Double { doanhThu.doanhThuQuyDoi }
    var targetQuyDoi: Double { doanhThu.targetQuyDoi }
    var phanTramQuyDoi: Double { doanhThu.phanTramQuyDoi }
    var phanTramTraGop: Double { doanhThu.phanTramTraGop }
    var luotKhach: Double { doanhThu.luotKhach }
    var soBill: Double { doanhThu.soBill }
    var coDuLieu: Bool {
        doanhThu.doanhThuThuc > 0 || doanhThu.doanhThuQuyDoi > 0 || doanhThu.luotKhach > 0 || doanhThu.soBill > 0
    }
}

struct DuLieuNgayDMX: Codable {
    var khoaNgay: String
    var capNhatLuc: String
    var thongTinDonVi: String
    var doanhThu: ThongTinDoanhThu
    var doanhThuRealtime: ThongTinDoanhThu = ThongTinDoanhThu()
    var danhSachThiDua: [DongThiDua]
    var danhSachThiDuaRealtime: [DongThiDua] = []
    var thiDuaNhanVien: [String: [String: Double]] = [:]
    var thiDuaNhanVienRealtime: [String: [String: Double]] = [:]
    var doanhThuNhanVien: [DoanhThuNhanVienItem] = []
    var doanhThuNhanVienRealtime: [DoanhThuNhanVienItem] = []

    init(
        khoaNgay: String,
        capNhatLuc: String,
        thongTinDonVi: String,
        doanhThu: ThongTinDoanhThu,
        doanhThuRealtime: ThongTinDoanhThu = ThongTinDoanhThu(),
        danhSachThiDua: [DongThiDua],
        danhSachThiDuaRealtime: [DongThiDua] = [],
        thiDuaNhanVien: [String: [String: Double]] = [:],
        thiDuaNhanVienRealtime: [String: [String: Double]] = [:],
        doanhThuNhanVien: [DoanhThuNhanVienItem] = [],
        doanhThuNhanVienRealtime: [DoanhThuNhanVienItem] = []
    ) {
        self.khoaNgay = khoaNgay
        self.capNhatLuc = capNhatLuc
        self.thongTinDonVi = thongTinDonVi
        self.doanhThu = doanhThu
        self.doanhThuRealtime = doanhThuRealtime
        self.danhSachThiDua = danhSachThiDua
        self.danhSachThiDuaRealtime = danhSachThiDuaRealtime
        self.thiDuaNhanVien = thiDuaNhanVien
        self.thiDuaNhanVienRealtime = thiDuaNhanVienRealtime
        self.doanhThuNhanVien = doanhThuNhanVien
        self.doanhThuNhanVienRealtime = doanhThuNhanVienRealtime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        khoaNgay = (try? c.decode(String.self, forKey: .khoaNgay)) ?? ""
        capNhatLuc = (try? c.decode(String.self, forKey: .capNhatLuc)) ?? ""
        thongTinDonVi = (try? c.decode(String.self, forKey: .thongTinDonVi)) ?? ""
        doanhThu = (try? c.decode(ThongTinDoanhThu.self, forKey: .doanhThu)) ?? ThongTinDoanhThu()
        doanhThuRealtime = (try? c.decode(ThongTinDoanhThu.self, forKey: .doanhThuRealtime)) ?? ThongTinDoanhThu()
        danhSachThiDua = (try? c.decode([DongThiDua].self, forKey: .danhSachThiDua)) ?? []
        danhSachThiDuaRealtime = (try? c.decode([DongThiDua].self, forKey: .danhSachThiDuaRealtime)) ?? []
        thiDuaNhanVien = (try? c.decode([String: [String: Double]].self, forKey: .thiDuaNhanVien)) ?? [:]
        thiDuaNhanVienRealtime = (try? c.decode([String: [String: Double]].self, forKey: .thiDuaNhanVienRealtime)) ?? [:]
        doanhThuNhanVien = (try? c.decode([DoanhThuNhanVienItem].self, forKey: .doanhThuNhanVien)) ?? []
        doanhThuNhanVienRealtime = (try? c.decode([DoanhThuNhanVienItem].self, forKey: .doanhThuNhanVienRealtime)) ?? []
    }

    func danhSachThiDua(theo cheDo: LoaiCheDoDoanhThu) -> [DongThiDua] {
        switch cheDo {
        case .luyKe: return danhSachThiDua
        case .realtime: return danhSachThiDuaRealtime
        }
    }

    mutating func ganDanhSachThiDua(_ ds: [DongThiDua], theo cheDo: LoaiCheDoDoanhThu) {
        switch cheDo {
        case .luyKe: danhSachThiDua = ds
        case .realtime: danhSachThiDuaRealtime = ds
        }
    }

    func thiDuaNhanVien(theo cheDo: LoaiCheDoDoanhThu) -> [String: [String: Double]] {
        switch cheDo {
        case .luyKe: return thiDuaNhanVien
        case .realtime: return thiDuaNhanVienRealtime
        }
    }

    mutating func ganThiDuaNhanVien(_ bang: [String: [String: Double]], theo cheDo: LoaiCheDoDoanhThu) {
        switch cheDo {
        case .luyKe: thiDuaNhanVien = bang
        case .realtime: thiDuaNhanVienRealtime = bang
        }
    }

    func doanhThuNhanVien(theo cheDo: LoaiCheDoDoanhThu) -> [DoanhThuNhanVienItem] {
        switch cheDo {
        case .luyKe: return doanhThuNhanVien
        case .realtime: return doanhThuNhanVienRealtime
        }
    }

    mutating func ganDoanhThuNhanVien(_ ds: [DoanhThuNhanVienItem], theo cheDo: LoaiCheDoDoanhThu) {
        switch cheDo {
        case .luyKe: doanhThuNhanVien = ds
        case .realtime: doanhThuNhanVienRealtime = ds
        }
    }
}

final class ThuMucDuLieu {
    static let dungChung = ThuMucDuLieu()

    let thuMuc: URL
    let tepNgay: URL
    let tepCaiDat: URL

    /// Không dùng prettyPrinted / sortedKeys để mã hoá JSON nhanh gấp 4 lần, không gây nghẽn CPU
    private let maHoa = JSONEncoder()
    private let giaiMa = JSONDecoder()
    private let hangDoiGhiFile = DispatchQueue(label: "com.thanhduong.tonghopdmx.ghifile", qos: .utility)
    private var congViecGhiNgay: DispatchWorkItem?
    private var congViecGhiCaiDat: DispatchWorkItem?

    private init() {
        let documents = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        thuMuc = documents.appendingPathComponent("DuLieuDMX", isDirectory: true)
        tepNgay = thuMuc.appendingPathComponent("du-lieu-dmx-v3.json")
        tepCaiDat = thuMuc.appendingPathComponent("cai-dat-dmx-v3.json")

        try? FileManager.default.createDirectory(at: thuMuc, withIntermediateDirectories: true)
    }

    func doc<T: Decodable>(_ loai: T.Type, tu tep: URL) -> T? {
        guard let duLieu = try? Data(contentsOf: tep) else { return nil }
        return try? giaiMa.decode(loai, from: duLieu)
    }

    @discardableResult
    func ghi<T: Encodable>(_ giaTri: T, vao tep: URL) -> Bool {
        do {
            let duLieu = try maHoa.encode(giaTri)
            try duLieu.write(to: tep, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    /// Ghi dữ liệu các ngày xuống đĩa trên luồng nền (debounce 0.35s) để tuyệt đối không làm đơ giao diện chính
    func ghiNgayBatDongBo(_ cacNgay: [String: DuLieuNgayDMX]) {
        let banSao = cacNgay
        let tep = tepNgay
        hangDoiGhiFile.async { [weak self] in
            guard let self else { return }
            self.congViecGhiNgay?.cancel()
            let cv = DispatchWorkItem { [weak self] in
                guard let self else { return }
                _ = self.ghi(banSao, vao: tep)
            }
            self.congViecGhiNgay = cv
            self.hangDoiGhiFile.asyncAfter(deadline: .now() + 0.35, execute: cv)
        }
    }

    /// Ghi dữ liệu cài đặt xuống đĩa trên luồng nền (debounce 0.25s)
    func ghiCaiDatBatDongBo(_ caiDat: CaiDatDMX) {
        let banSao = caiDat
        let tep = tepCaiDat
        hangDoiGhiFile.async { [weak self] in
            guard let self else { return }
            self.congViecGhiCaiDat?.cancel()
            let cv = DispatchWorkItem { [weak self] in
                guard let self else { return }
                _ = self.ghi(banSao, vao: tep)
            }
            self.congViecGhiCaiDat = cv
            self.hangDoiGhiFile.asyncAfter(deadline: .now() + 0.25, execute: cv)
        }
    }
}

final class KhoDuLieu {
    static let dungChung = KhoDuLieu()

    private let khoaTruyCap = NSRecursiveLock()
    private(set) var cacNgay: [String: DuLieuNgayDMX] = [:]
    var caiDat = CaiDatDMX()

    /// Bộ nhớ đệm trong RAM giúp chuyển đổi qua lại giữa các tab cực nhanh, không phải chạy lại Regex chuẩn hoá chuỗi lặp đi lặp lại
    private var boNhoDemDuLieuNgay: [String: DuLieuNgayDMX] = [:]
    private static let khoaBoNhoDemTinh = NSLock()
    private static var boNhoDemKhoaSoSanh: [String: String] = [:]
    private static var boNhoDemLocTen: [String: String] = [:]

    private init() {
        doc()
    }

    /// Lấy bản sao an toàn của toàn bộ dữ liệu để đồng bộ nền mà không tranh chấp bộ nhớ với luồng chính
    func layBanSaoAnToan() -> (caiDat: CaiDatDMX, cacNgay: [String: DuLieuNgayDMX]) {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        return (caiDat, cacNgay)
    }

    private func xoaBoNhoDem(xoaonLocTen: Bool = false) {
        khoaTruyCap.lock()
        boNhoDemDuLieuNgay.removeAll(keepingCapacity: true)
        khoaTruyCap.unlock()
        if xoaonLocTen {
            Self.khoaBoNhoDemTinh.lock()
            Self.boNhoDemLocTen.removeAll(keepingCapacity: true)
            Self.khoaBoNhoDemTinh.unlock()
        }
    }

    func doc() {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let thuMuc = ThuMucDuLieu.dungChung
        if let cd = thuMuc.doc(CaiDatDMX.self, tu: thuMuc.tepCaiDat) {
            caiDat = cd
        } else {
            thuMuc.ghiCaiDatBatDongBo(caiDat)
        }

        if let giaTri = thuMuc.doc([String: DuLieuNgayDMX].self, tu: thuMuc.tepNgay) {
            cacNgay = giaTri
        } else {
            thuMuc.ghiNgayBatDongBo(cacNgay)
        }
        xoaBoNhoDem(xoaonLocTen: true)
    }

    /// Lấy Doanh thu Lũy kế cố định của tháng (mỗi lần nhập ở ngày mới sẽ thay thế cho ngày hôm trước)
    func doanhThuLuyKeThang(cho ngay: Date) -> ThongTinDoanhThu {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoa = TienIchNgay.khoa.string(from: ngay)
        let tienTo = String(khoa.prefix(7))
        if let hienTai = cacNgay[khoa]?.doanhThu, hienTai.coDuLieu {
            return hienTai
        }
        for k in cacNgay.keys.filter({ $0.hasPrefix(tienTo) }).sorted(by: >) {
            if let dt = cacNgay[k]?.doanhThu, dt.coDuLieu {
                return dt
            }
        }
        return ThongTinDoanhThu()
    }

    /// Lấy Doanh thu Lũy kế Nhân viên của tháng (khi nhập mới sẽ thay thế dữ liệu cũ)
    func doanhThuNhanVienLuyKeThang(cho ngay: Date) -> [DoanhThuNhanVienItem] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoa = TienIchNgay.khoa.string(from: ngay)
        let tienTo = String(khoa.prefix(7))
        if let hienTai = cacNgay[khoa]?.doanhThuNhanVien, !hienTai.isEmpty {
            return hienTai
        }
        for k in cacNgay.keys.filter({ $0.hasPrefix(tienTo) }).sorted(by: >) {
            if let ds = cacNgay[k]?.doanhThuNhanVien, !ds.isEmpty {
                return ds
            }
        }
        return []
    }

    /// Xoá Doanh thu Lũy kế Nhân viên của tháng (để dữ liệu cũ không còn tồn đọng)
    func xoaDoanhThuNhanVienLuyKeThang(cho ngay: Date, xoaCaThiDuaNV: Bool = false) {
        khoaTruyCap.lock()
        let khoa = TienIchNgay.khoa.string(from: ngay)
        let tienTo = String(khoa.prefix(7))
        for k in cacNgay.keys where k.hasPrefix(tienTo) {
            cacNgay[k]?.doanhThuNhanVien = []
            if xoaCaThiDuaNV {
                cacNgay[k]?.thiDuaNhanVien = [:]
            }
        }
        xoaBoNhoDem()
        var dl = duLieu(cho: ngay)
        dl.doanhThuNhanVien = []
        if xoaCaThiDuaNV {
            dl.thiDuaNhanVien = [:]
        }
        cacNgay[khoa] = dl
        xoaBoNhoDem()
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
        DichVuDongBo.dungChung.dayDuLieuNgay(dl)
    }

    /// Xoá Doanh thu Lũy kế cố định của tháng
    func xoaDoanhThuLuyKeThang(cho ngay: Date) {
        khoaTruyCap.lock()
        let khoa = TienIchNgay.khoa.string(from: ngay)
        let tienTo = String(khoa.prefix(7))
        for k in cacNgay.keys where k.hasPrefix(tienTo) {
            cacNgay[k]?.doanhThu = ThongTinDoanhThu()
        }
        xoaBoNhoDem()
        var dl = duLieu(cho: ngay)
        dl.doanhThu = ThongTinDoanhThu()
        cacNgay[khoa] = dl
        xoaBoNhoDem()
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
        DichVuDongBo.dungChung.dayDuLieuNgay(dl)
    }

    /// Khóa tháng dạng "yyyy-MM"
    func khoaThang(cho ngay: Date) -> String {
        let k = TienIchNgay.khoa.string(from: ngay)
        return String(k.prefix(7))
    }

    /// Số ngày thực tế của tháng (28, 29, 30 hoặc 31)
    func soNgayTrongThang(cho ngay: Date) -> Int {
        TienIchNgay.lich.range(of: .day, in: .month, for: ngay)?.count ?? 30
    }

    /// Lấy Mục tiêu Doanh thu Quy đổi tháng từ Target QĐ Lũy kế đã quét
    func mucTieuDoanhThuQDThang(cho ngay: Date) -> Double {
        let lk = doanhThuLuyKeThang(cho: ngay)
        if lk.targetQuyDoi > 0 {
            return lk.targetQuyDoi
        }
        return 0
    }

    /// Tính toán Dự báo Doanh thu QĐ cuối tháng, % HT QĐ dự kiến & % Quy đổi dự kiến cho bảng Biểu đồ tháng.
    func tinhDuBaoQuyDoiTuRealtime(cho ngay: Date, cheDoDangXem: LoaiCheDoDoanhThu = .realtime) -> DuBaoQuyDoiThang {
        let soNgay = max(1, soNgayTrongThang(cho: ngay))
        let lk = doanhThuLuyKeThang(cho: ngay)
        let mucTieuThang = lk.targetQuyDoi
        let mucTieuNgay = mucTieuThang > 0 ? (mucTieuThang / Double(soNgay)) : 0

        let khoaDen = TienIchNgay.khoa.string(from: ngay)
        let tatCaNgay = danhSachRealtimeTheoNgayTrongThang(cho: ngay)
        let cacNgayCoRTDenNgay = tatCaNgay.filter { $0.khoaNgay <= khoaDen && ($0.doanhThuQuyDoi > 0 || $0.doanhThuThuc > 0) }
        let cacNgayCoRTTrongThang = tatCaNgay.filter { $0.doanhThuQuyDoi > 0 || $0.doanhThuThuc > 0 }
        let cacNgayCoRT = !cacNgayCoRTDenNgay.isEmpty ? cacNgayCoRTDenNgay : cacNgayCoRTTrongThang

        let dlNgayChon = duLieu(cho: ngay)

        var soNgayTinh = cacNgayCoRT.count
        var tongQD = cacNgayCoRT.reduce(0.0) { $0 + $1.doanhThuQuyDoi }
        var tongThuc = cacNgayCoRT.reduce(0.0) { $0 + $1.doanhThuThuc }

        let tbQDMoiNgay: Double
        let tbThucMoiNgay: Double

        if soNgayTinh > 0 {
            tbQDMoiNgay = tongQD / Double(soNgayTinh)
            tbThucMoiNgay = tongThuc / Double(soNgayTinh)
        } else if lk.coDuLieu {
            let ngayDaQua = lk.soNgayDaQua > 0 ? lk.soNgayDaQua : max(1, TienIchNgay.lich.component(.day, from: ngay))
            soNgayTinh = ngayDaQua
            tongQD = lk.doanhThuQuyDoi
            tongThuc = lk.doanhThuThuc
            tbQDMoiNgay = ngayDaQua > 0 ? (lk.doanhThuQuyDoi / Double(ngayDaQua)) : 0
            tbThucMoiNgay = ngayDaQua > 0 ? (lk.doanhThuThuc / Double(ngayDaQua)) : 0
        } else {
            tbQDMoiNgay = 0
            tbThucMoiNgay = 0
        }

        let duKienQDCuoiThang = lk.duKienQuyDoi > 0 ? lk.duKienQuyDoi : (tbQDMoiNgay * Double(soNgay))
        let duKienThucCuoiThang = lk.duKienThuc > 0 ? lk.duKienThuc : (tbThucMoiNgay * Double(soNgay))

        let phanTramHTQDDuKien: Double
        if lk.phanTramHTQuyDoi > 0 {
            phanTramHTQDDuKien = lk.phanTramHTQuyDoi
        } else if dlNgayChon.doanhThuRealtime.phanTramHTQuyDoi > 0 {
            phanTramHTQDDuKien = dlNgayChon.doanhThuRealtime.phanTramHTQuyDoi
        } else if mucTieuThang > 0, duKienQDCuoiThang > 0 {
            phanTramHTQDDuKien = (duKienQDCuoiThang / mucTieuThang) * 100.0
        } else if dlNgayChon.doanhThuRealtime.targetQuyDoi > 0, tbQDMoiNgay > 0 {
            phanTramHTQDDuKien = (tbQDMoiNgay / dlNgayChon.doanhThuRealtime.targetQuyDoi) * 100.0
        } else {
            phanTramHTQDDuKien = 0
        }

        let phanTramQDDuKien: Double
        if duKienThucCuoiThang > 0, duKienQDCuoiThang > 0 {
            phanTramQDDuKien = ((duKienQDCuoiThang - duKienThucCuoiThang) / duKienThucCuoiThang) * 100.0
        } else {
            let dt = (cheDoDangXem == .luyKe) ? dlNgayChon.doanhThu : dlNgayChon.doanhThuRealtime
            phanTramQDDuKien = dt.phanTramQuyDoi
        }

        return DuBaoQuyDoiThang(
            mucTieuThang: mucTieuThang,
            soNgayTrongThang: soNgay,
            mucTieuMoiNgay: mucTieuNgay,
            soNgayCoRealtime: soNgayTinh,
            tongDTThucRealtime: tongThuc,
            tongDTQDRealtime: tongQD,
            trungBinhThucMoiNgay: tbThucMoiNgay,
            trungBinhQDMoiNgay: tbQDMoiNgay,
            duKienThucCuoiThang: duKienThucCuoiThang,
            duKienQDCuoiThang: duKienQDCuoiThang,
            phanTramHTQDDuKien: phanTramHTQDDuKien,
            phanTramQuyDoiDuKien: phanTramQDDuKien
        )
    }

    /// Danh sách Doanh thu Realtime (Thực & Quy đổi) theo từng ngày trong tháng để vẽ đồ thị cột và bảng tổng hợp
    func danhSachRealtimeTheoNgayTrongThang(cho ngay: Date) -> [DuLieuRealtimeNgayTrongThang] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let lich = TienIchNgay.lich
        let nam = lich.component(.year, from: ngay)
        let thang = lich.component(.month, from: ngay)
        let soNgay = lich.range(of: .day, in: .month, for: ngay)?.count ?? 30

        var ketQua: [DuLieuRealtimeNgayTrongThang] = []
        ketQua.reserveCapacity(soNgay)
        for d in 1...soNgay {
            var comp = DateComponents()
            comp.year = nam
            comp.month = thang
            comp.day = d
            let ngayD = lich.date(from: comp) ?? ngay
            let khoa = String(format: "%04d-%02d-%02d", nam, thang, d)
            let rt = cacNgay[khoa]?.doanhThuRealtime ?? ThongTinDoanhThu()
            ketQua.append(
                DuLieuRealtimeNgayTrongThang(
                    ngay: ngayD,
                    khoaNgay: khoa,
                    ngayTrongThang: d,
                    doanhThu: rt
                )
            )
        }
        return ketQua
    }

    func duLieu(cho ngay: Date) -> DuLieuNgayDMX {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoa = TienIchNgay.khoa.string(from: ngay)
        if let daDem = boNhoDemDuLieuNgay[khoa] {
            return daDem
        }

        let tienTo = String(khoa.prefix(7))
        let luyKeThang = doanhThuLuyKeThang(cho: ngay)
        let dtNVLuyKeThang = doanhThuNhanVienLuyKeThang(cho: ngay)

        // Tìm target Lũy kế & Realtime gần nhất trong tháng (tách biệt hoàn toàn giữa Lũy kế và Realtime)
        var targetTheoKhoaTrongThang: [String: Double] = [:]
        var targetRealtimeTheoKhoaTrongThang: [String: Double] = [:]
        for kNgay in cacNgay.keys.filter({ $0.hasPrefix(tienTo) && $0 <= khoa }).sorted() {
            guard let dlNgay = cacNgay[kNgay] else { continue }
            for d in dlNgay.danhSachThiDua where d.target > 0 {
                let k1 = Self.chuanHoaKhoaSoSanh(Self.apDungLocTuCaiDat(d.tenNganhHangGoc))
                let k2 = Self.chuanHoaKhoaSoSanh(d.tenNganhHangGoc)
                if !k1.isEmpty { targetTheoKhoaTrongThang[k1] = d.target }
                if !k2.isEmpty { targetTheoKhoaTrongThang[k2] = d.target }
            }
            for d in dlNgay.danhSachThiDuaRealtime where d.target > 0 {
                let k1 = Self.chuanHoaKhoaSoSanh(Self.apDungLocTuCaiDat(d.tenNganhHangGoc))
                let k2 = Self.chuanHoaKhoaSoSanh(d.tenNganhHangGoc)
                if !k1.isEmpty { targetRealtimeTheoKhoaTrongThang[k1] = d.target }
                if !k2.isEmpty { targetRealtimeTheoKhoaTrongThang[k2] = d.target }
            }
        }

        if var coSan = cacNgay[khoa] {
            if !coSan.doanhThu.coDuLieu && luyKeThang.coDuLieu {
                coSan.doanhThu = luyKeThang
            }
            if coSan.doanhThuNhanVien.isEmpty && !dtNVLuyKeThang.isEmpty {
                coSan.doanhThuNhanVien = dtNVLuyKeThang
            }
            for i in coSan.danhSachThiDua.indices {
                let goc = coSan.danhSachThiDua[i].tenNganhHangGoc
                coSan.danhSachThiDua[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
                if coSan.danhSachThiDua[i].target <= 0 {
                    let k1 = Self.chuanHoaKhoaSoSanh(coSan.danhSachThiDua[i].tenNganhHang)
                    let k2 = Self.chuanHoaKhoaSoSanh(goc)
                    if let t = targetTheoKhoaTrongThang[k1] ?? targetTheoKhoaTrongThang[k2], t > 0 {
                        coSan.danhSachThiDua[i].target = t
                    }
                }
            }
            coSan.danhSachThiDua = Self.gopDanhSachThiDua(cu: [], moi: coSan.danhSachThiDua)

            for i in coSan.danhSachThiDuaRealtime.indices {
                let goc = coSan.danhSachThiDuaRealtime[i].tenNganhHangGoc
                coSan.danhSachThiDuaRealtime[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
                if coSan.danhSachThiDuaRealtime[i].target <= 0 {
                    let k1 = Self.chuanHoaKhoaSoSanh(coSan.danhSachThiDuaRealtime[i].tenNganhHang)
                    let k2 = Self.chuanHoaKhoaSoSanh(goc)
                    if let t = targetRealtimeTheoKhoaTrongThang[k1] ?? targetRealtimeTheoKhoaTrongThang[k2], t > 0 {
                        coSan.danhSachThiDuaRealtime[i].target = t
                    }
                }
            }
            coSan.danhSachThiDuaRealtime = Self.gopDanhSachThiDua(cu: [], moi: coSan.danhSachThiDuaRealtime)
            boNhoDemDuLieuNgay[khoa] = coSan
            return coSan
        }

        let moi = DuLieuNgayDMX(
            khoaNgay: khoa,
            capNhatLuc: "",
            thongTinDonVi: "",
            doanhThu: luyKeThang,
            doanhThuRealtime: ThongTinDoanhThu(),
            danhSachThiDua: [],
            danhSachThiDuaRealtime: [],
            doanhThuNhanVien: dtNVLuyKeThang
        )
        boNhoDemDuLieuNgay[khoa] = moi
        return moi
    }

    func luu(_ duLieu: DuLieuNgayDMX) {
        khoaTruyCap.lock()
        var banLuu = duLieu
        let tienTo = String(banLuu.khoaNgay.prefix(7))

        for i in banLuu.danhSachThiDua.indices {
            let goc = banLuu.danhSachThiDua[i].tenNganhHangGoc
            banLuu.danhSachThiDua[i].tenNganhHang = Self.apDungLocTuCaiDat(goc)
        }
        banLuu.danhSachThiDua = Self.gopDanhSachThiDua(cu: [], moi: banLuu.danhSachThiDua)

        for i in banLuu.danhSachThiDuaRealtime.indices {
            let goc = banLuu.danhSachThiDuaRealtime[i].tenNganhHangGoc
            banLuu.danhSachThiDuaRealtime[i].tenNganhHang = Self.apDungLocTuCaiDat(goc)
        }
        banLuu.danhSachThiDuaRealtime = Self.gopDanhSachThiDua(cu: [], moi: banLuu.danhSachThiDuaRealtime)

        // Doanh thu Lũy kế là cố định của tháng: khi người dùng nhập vào mỗi ngày sẽ thay thế cho ngày hôm trước trong cùng tháng
        if banLuu.doanhThu.coDuLieu {
            for k in cacNgay.keys where k.hasPrefix(tienTo) {
                cacNgay[k]?.doanhThu = banLuu.doanhThu
            }
        } else {
            for k in cacNgay.keys.filter({ $0.hasPrefix(tienTo) && $0 != banLuu.khoaNgay }).sorted(by: >) {
                if let dtCu = cacNgay[k]?.doanhThu, dtCu.coDuLieu {
                    banLuu.doanhThu = dtCu
                    break
                }
            }
        }

        // Doanh thu Lũy kế nhân viên: mỗi khi nhập mới sẽ thay thế hoàn toàn dữ liệu cũ của tháng
        if !banLuu.doanhThuNhanVien.isEmpty {
            for k in cacNgay.keys where k.hasPrefix(tienTo) {
                cacNgay[k]?.doanhThuNhanVien = banLuu.doanhThuNhanVien
            }
        } else {
            for k in cacNgay.keys.filter({ $0.hasPrefix(tienTo) && $0 != banLuu.khoaNgay }).sorted(by: >) {
                if let dsCu = cacNgay[k]?.doanhThuNhanVien, !dsCu.isEmpty {
                    banLuu.doanhThuNhanVien = dsCu
                    break
                }
            }
        }

        cacNgay[banLuu.khoaNgay] = banLuu
        xoaBoNhoDem()
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
        DichVuDongBo.dungChung.dayDuLieuNgay(banLuu)
    }

    func luuCaiDat(_ moi: CaiDatDMX) {
        khoaTruyCap.lock()
        let doiCumTu = (caiDat.danhSachCumTuLocBo != moi.danhSachCumTuLocBo)
        caiDat = moi
        xoaBoNhoDem(xoaonLocTen: doiCumTu)
        let banSaoCaiDat = moi
        var banSaoNgayCanLuu: [String: DuLieuNgayDMX]?
        if doiCumTu {
            for (khoa, var dl) in cacNgay {
                for i in dl.danhSachThiDua.indices {
                    let goc = dl.danhSachThiDua[i].tenNganhHangGoc
                    dl.danhSachThiDua[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
                }
                dl.danhSachThiDua = Self.gopDanhSachThiDua(cu: [], moi: dl.danhSachThiDua)

                for i in dl.danhSachThiDuaRealtime.indices {
                    let goc = dl.danhSachThiDuaRealtime[i].tenNganhHangGoc
                    dl.danhSachThiDuaRealtime[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
                }
                dl.danhSachThiDuaRealtime = Self.gopDanhSachThiDua(cu: [], moi: dl.danhSachThiDuaRealtime)
                cacNgay[khoa] = dl
            }
            xoaBoNhoDem()
            banSaoNgayCanLuu = cacNgay
        }
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiCaiDatBatDongBo(banSaoCaiDat)
        if let banSaoNgayCanLuu {
            ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgayCanLuu)
        }
        DichVuDongBo.dungChung.dayCaiDat(moi)
    }

    /// Chuẩn hoá dữ liệu tải về từ đám mây trên luồng nền rồi gán nhanh vào bộ nhớ để tránh làm khựng giao diện người dùng
    func nhapDuLieuDamMay(caiDat moi: CaiDatDMX?, cacNgay ngayMoi: [String: DuLieuNgayDMX]) {
        khoaTruyCap.lock()
        if let moi { caiDat = moi }
        xoaBoNhoDem(xoaonLocTen: true)
        for (khoa, var duLieu) in ngayMoi {
            duLieu.khoaNgay = khoa
            for i in duLieu.danhSachThiDua.indices {
                let goc = duLieu.danhSachThiDua[i].tenNganhHangGoc
                duLieu.danhSachThiDua[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
            }
            duLieu.danhSachThiDua = Self.gopDanhSachThiDua(cu: [], moi: duLieu.danhSachThiDua)

            for i in duLieu.danhSachThiDuaRealtime.indices {
                let goc = duLieu.danhSachThiDuaRealtime[i].tenNganhHangGoc
                duLieu.danhSachThiDuaRealtime[i].tenNganhHang = KhoDuLieu.apDungLocTuCaiDat(goc)
            }
            duLieu.danhSachThiDuaRealtime = Self.gopDanhSachThiDua(cu: [], moi: duLieu.danhSachThiDuaRealtime)
            cacNgay[khoa] = duLieu
        }
        xoaBoNhoDem()
        let banSaoCaiDat = caiDat
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiCaiDatBatDongBo(banSaoCaiDat)
        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
    }

    func datLaiSauDangXuat() {
        khoaTruyCap.lock()
        caiDat = CaiDatDMX()
        cacNgay = [:]
        xoaBoNhoDem(xoaonLocTen: true)
        let banSaoCaiDat = caiDat
        let banSaoNgay = cacNgay
        khoaTruyCap.unlock()

        ThuMucDuLieu.dungChung.ghiCaiDatBatDongBo(banSaoCaiDat)
        ThuMucDuLieu.dungChung.ghiNgayBatDongBo(banSaoNgay)
    }

    /// Danh sách mặt hàng đồng bộ theo chế độ đang xem (Lũy kế hoặc Realtime)
    func danhSachMatHangThang(den ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> [DongThiDua] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let dlNgay = duLieu(cho: ngay)
        if cheDo == .realtime {
            if !dlNgay.danhSachThiDuaRealtime.isEmpty {
                return dlNgay.danhSachThiDuaRealtime
            }
            let khoaDen = TienIchNgay.khoa.string(from: ngay)
            let tienTo = String(khoaDen.prefix(7))
            let cacKhoa = cacNgay.keys.filter { $0.hasPrefix(tienTo) && $0 <= khoaDen }.sorted(by: >)
            for khoa in cacKhoa {
                if let dl = cacNgay[khoa], !dl.danhSachThiDuaRealtime.isEmpty {
                    var ds = dl.danhSachThiDuaRealtime
                    for i in ds.indices {
                        ds[i].tenNganhHang = Self.apDungLocTuCaiDat(ds[i].tenNganhHangGoc)
                    }
                    return Self.gopDanhSachThiDua(cu: [], moi: ds)
                }
            }
            if !dlNgay.danhSachThiDua.isEmpty {
                return dlNgay.danhSachThiDua
            }
        } else {
            if !dlNgay.danhSachThiDua.isEmpty {
                return dlNgay.danhSachThiDua
            }
            let khoaDen = TienIchNgay.khoa.string(from: ngay)
            let tienTo = String(khoaDen.prefix(7))
            let cacKhoa = cacNgay.keys.filter { $0.hasPrefix(tienTo) && $0 <= khoaDen }.sorted(by: >)
            for khoa in cacKhoa {
                if let dl = cacNgay[khoa], !dl.danhSachThiDua.isEmpty {
                    var ds = dl.danhSachThiDua
                    for i in ds.indices {
                        ds[i].tenNganhHang = Self.apDungLocTuCaiDat(ds[i].tenNganhHangGoc)
                    }
                    return Self.gopDanhSachThiDua(cu: [], moi: ds)
                }
            }
            if !dlNgay.danhSachThiDuaRealtime.isEmpty {
                return dlNgay.danhSachThiDuaRealtime
            }
        }
        return []
    }

    /// Lấy danh sách mã NV được chia Target cho 1 ngành hàng (đồng bộ cả khóa tên đã lọc và khóa tên gốc)
    func danhSachMaNVChiaTarget(cho dong: DongThiDua, trong tapCaiDat: CaiDatDMX? = nil) -> [String] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let cd = tapCaiDat ?? caiDat
        let tatCaMa = cd.danhSachNhanVien.map(\.maNV)
        let k1 = Self.chuanHoaKhoaSoSanh(dong.tenNganhHang)
        let k2 = Self.chuanHoaKhoaSoSanh(dong.tenNganhHangGoc)
        if let ds = cd.chiaTargetNganhHang[k1] ?? cd.chiaTargetNganhHang[k2] {
            return ds.filter { tatCaMa.contains($0) }
        }
        return tatCaMa
    }

    /// Đồng bộ cập nhật Target & ĐVT (DT/SL) của 1 ngành hàng từ màn hình Chia Target (Cài đặt) sang Bảng Thi Đua
    func capNhatTargetNganhHang(dongGoc: DongThiDua, targetMoi: Double, loaiChiTieuMoi: LoaiChiTieuThiDua? = nil, cho ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) {
        khoaTruyCap.lock()
        let k1 = Self.chuanHoaKhoaSoSanh(dongGoc.tenNganhHang)
        let k2 = Self.chuanHoaKhoaSoSanh(dongGoc.tenNganhHangGoc)
        var dl = duLieu(cho: ngay)
        var ds = dl.danhSachThiDua(theo: cheDo)
        var daCapNhat = false
        for i in ds.indices {
            let dk1 = Self.chuanHoaKhoaSoSanh(ds[i].tenNganhHang)
            let dk2 = Self.chuanHoaKhoaSoSanh(ds[i].tenNganhHangGoc)
            if ds[i].id == dongGoc.id || dk1 == k1 || dk2 == k2 {
                ds[i].target = targetMoi
                if let loai = loaiChiTieuMoi {
                    ds[i].loaiChiTieu = loai
                }
                daCapNhat = true
            }
        }
        if daCapNhat {
            dl.ganDanhSachThiDua(ds, theo: cheDo)
            khoaTruyCap.unlock()
            luu(dl)
        } else {
            let khoaDen = TienIchNgay.khoa.string(from: ngay)
            let tienTo = String(khoaDen.prefix(7))
            let cacKhoa = cacNgay.keys.filter { $0.hasPrefix(tienTo) && $0 <= khoaDen }.sorted(by: >)
            var dlCanLuu: DuLieuNgayDMX?
            for khoa in cacKhoa {
                guard var dlCu = cacNgay[khoa] else { continue }
                var dsCu = dlCu.danhSachThiDua(theo: cheDo)
                guard !dsCu.isEmpty else { continue }
                for i in dsCu.indices {
                    let dk1 = Self.chuanHoaKhoaSoSanh(Self.apDungLocTuCaiDat(dsCu[i].tenNganhHangGoc))
                    let dk2 = Self.chuanHoaKhoaSoSanh(dsCu[i].tenNganhHangGoc)
                    if dk1 == k1 || dk2 == k2 {
                        dsCu[i].target = targetMoi
                        if let loai = loaiChiTieuMoi {
                            dsCu[i].loaiChiTieu = loai
                        }
                    }
                }
                dlCu.ganDanhSachThiDua(dsCu, theo: cheDo)
                dlCanLuu = dlCu
                break
            }
            khoaTruyCap.unlock()
            if let dlCanLuu {
                luu(dlCanLuu)
            }
        }
    }

    /// Tổng hợp số thực hiện của từng nhân viên theo từng mặt hàng theo chế độ Lũy kế hoặc Realtime
    func thucHienNhanVienTheoMatHangThang(den ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> [String: [String: Double]] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        if cheDo == .realtime {
            return duLieu(cho: ngay).thiDuaNhanVienRealtime
        }

        let khoaDen = TienIchNgay.khoa.string(from: ngay)
        let tienTo = String(khoaDen.prefix(7))
        var cacKhoa = cacNgay.keys.filter { $0.hasPrefix(tienTo) && $0 <= khoaDen }.sorted()
        if !cacKhoa.contains(khoaDen) {
            cacKhoa.append(khoaDen)
        }

        var ketQua: [String: [String: Double]] = [:]
        for khoa in cacKhoa {
            let dl = (khoa == khoaDen) ? duLieu(cho: ngay) : cacNgay[khoa]
            guard let bangNganh = dl?.thiDuaNhanVien else { continue }
            for (khoaNganh, bangNV) in bangNganh {
                ketQua[khoaNganh, default: [:]].merge(bangNV) { _, moi in moi }
            }
        }
        return ketQua
    }

    /// Danh sách xếp hạng nhân viên cho 1 ngành hàng cụ thể (chia theo Lũy kế hoặc Realtime)
    func danhSachXepHangNhanVien(cho dong: DongThiDua, den ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> [DongXepHangNhanVienNganh] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let khoaNganh = Self.chuanHoaKhoaSoSanh(dong.tenNganhHang)
        let dsMaDuocChon = danhSachMaNVChiaTarget(cho: dong)
        let soNV = dsMaDuocChon.count
        guard soNV > 0 else { return [] }

        let targetCaNhan = dong.target / Double(soNV)
        let bangTH = thucHienNhanVienTheoMatHangThang(den: ngay, cheDo: cheDo)[khoaNganh] ?? [:]

        return dsMaDuocChon.map { maNV in
            let nv = caiDat.danhSachNhanVien.first(where: { $0.maNV == maNV }) ?? NhanVienQuanLy(maNV: maNV, hoTen: "NV \(maNV)")
            let thucHien = bangTH[maNV] ?? 0
            let phanTramHT = targetCaNhan > 0.0001 ? (thucHien / targetCaNhan) * 100.0 : 0
            return DongXepHangNhanVienNganh(
                maNV: maNV,
                hoTen: nv.hoTen,
                thucHien: thucHien,
                targetCaNhan: targetCaNhan,
                phanTramHT: phanTramHT
            )
        }.sorted {
            if abs($0.phanTramHT - $1.phanTramHT) > 0.001 {
                return $0.phanTramHT > $1.phanTramHT
            }
            return $0.thucHien > $1.thucHien
        }
    }

    /// Bảng tổng hợp nhân viên (chia theo Lũy kế hoặc Realtime).
    func tongHopNhanVien(
        den ngay: Date,
        sapXep: KieuSapXepNhanVien = .soMonHoanThanh,
        cheDo: LoaiCheDoDoanhThu = .luyKe
    ) -> [TongHopNhanVien] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        let matHang = danhSachMatHangThang(den: ngay, cheDo: cheDo)
        let thucHienTheoNganh = thucHienNhanVienTheoMatHangThang(den: ngay, cheDo: cheDo)
        let dlHienTai = duLieu(cho: ngay)
        let dtNVList: [DoanhThuNhanVienItem]
        if cheDo == .luyKe {
            dtNVList = !dlHienTai.doanhThuNhanVien.isEmpty
                ? dlHienTai.doanhThuNhanVien
                : doanhThuNhanVienLuyKeThang(cho: ngay)
        } else {
            dtNVList = dlHienTai.doanhThuNhanVienRealtime
        }

        let dsNV = caiDat.danhSachNhanVien
        var ketQua: [TongHopNhanVien] = dsNV.map { nv in
            var cacMonGiao: [MonThiDuaNhanVien] = []
            cacMonGiao.reserveCapacity(matHang.count)
            for mh in matHang {
                let khoa = Self.chuanHoaKhoaSoSanh(mh.tenNganhHang)
                let dsMaDuocGiao = danhSachMaNVChiaTarget(cho: mh)
                guard dsMaDuocGiao.contains(nv.maNV) else { continue }

                let soNguoiNhan = max(1, dsMaDuocGiao.count)
                let targetCaNhan = mh.target / Double(soNguoiNhan)
                let thucHien = thucHienTheoNganh[khoa]?[nv.maNV] ?? 0
                let phanTramHT = targetCaNhan > 0.0001 ? (thucHien / targetCaNhan) * 100.0 : 0
                let phanTramSieuThi = mh.target > 0.0001 ? (mh.thucHien / mh.target) * 100.0 : 0

                cacMonGiao.append(MonThiDuaNhanVien(
                    khoaNganh: khoa,
                    tenNganhHang: mh.tenNganhHang,
                    loaiChiTieu: mh.loaiChiTieu,
                    thucHien: thucHien,
                    targetCaNhan: targetCaNhan,
                    phanTramHT: phanTramHT,
                    phanTramSieuThi: phanTramSieuThi
                ))
            }

            cacMonGiao.sort { $0.phanTramHT > $1.phanTramHT }
            let soMonDat = cacMonGiao.filter(\.daDat).count
            let tongMonGiao = cacMonGiao.count
            let phanTramHTTB = tongMonGiao > 0 ? cacMonGiao.map(\.phanTramHT).reduce(0, +) / Double(tongMonGiao) : 0

            let dtCaNhan = dtNVList.first(where: {
                Self.chuanHoaMaNV($0.maNV) == nv.maNV ||
                Self.khopNhanVienQuetVoiQuanLy(maQuet: $0.maNV, tenQuet: $0.hoTen, dsQuanLy: [nv]) != nil
            })

            return TongHopNhanVien(
                nhanVien: nv,
                soMonDat: soMonDat,
                tongMonGiao: tongMonGiao,
                phanTramHTTB: phanTramHTTB,
                doanhThuQD: dtCaNhan?.doanhThuQD ?? 0,
                soLuongDon: dtCaNhan?.soLuong ?? 0,
                phanTramTyTrong: dtCaNhan?.phanTramTyTrong ?? 0,
                cacMonGiao: cacMonGiao,
                doanhThuCaNhan: dtCaNhan
            )
        }

        switch sapXep {
        case .soMonHoanThanh:
            ketQua.sort {
                if $0.soMonDat != $1.soMonDat { return $0.soMonDat > $1.soMonDat }
                if abs($0.phanTramHTTB - $1.phanTramHTTB) > 0.001 { return $0.phanTramHTTB > $1.phanTramHTTB }
                return $0.doanhThuQD > $1.doanhThuQD
            }
        case .doanhThuQD:
            ketQua.sort {
                if abs($0.doanhThuQD - $1.doanhThuQD) > 0.001 { return $0.doanhThuQD > $1.doanhThuQD }
                return $0.soMonDat > $1.soMonDat
            }
        case .phanTramTB:
            ketQua.sort {
                if abs($0.phanTramHTTB - $1.phanTramHTTB) > 0.001 { return $0.phanTramHTTB > $1.phanTramHTTB }
                return $0.soMonDat > $1.soMonDat
            }
        }
        return ketQua
    }

    /// Gộp kết quả quét thực hiện nhân viên theo ngành hàng vào dữ liệu ngày (theo chế độ Lũy kế hoặc Realtime)
    func gopKetQuaThiDuaNhanVien(
        hienTai: [String: [String: Double]],
        mangKhoiNV: [KetQuaThiDuaNhanVienKhoi],
        ngay: Date,
        cheDo: LoaiCheDoDoanhThu = .luyKe,
        khoaNganhMacDinh: String? = nil
    ) -> [String: [String: Double]] {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }
        var ketQua = hienTai
        var matHangThang = danhSachMatHangThang(den: ngay, cheDo: cheDo)
        if matHangThang.isEmpty {
            matHangThang = danhSachMatHangThang(den: ngay, cheDo: .luyKe)
        }

        for khoi in mangKhoiNV {
            let tenLoc = Self.apDungLocTuCaiDat(khoi.tenNganhHang)
            var khoaNganh = Self.chuanHoaKhoaSoSanh(tenLoc)

            if !khoaNganh.isEmpty {
                if let khop = matHangThang.first(where: {
                    let k = Self.chuanHoaKhoaSoSanh($0.tenNganhHang)
                    return k == khoaNganh || k.contains(khoaNganh) || khoaNganh.contains(k)
                }) {
                    khoaNganh = Self.chuanHoaKhoaSoSanh(khop.tenNganhHang)
                }
            }
            if (khoaNganh.isEmpty || khoaNganh == "NGANH HANG"), let macDinh = khoaNganhMacDinh, !macDinh.isEmpty {
                khoaNganh = macDinh
            }
            guard !khoaNganh.isEmpty else { continue }

            var bangCu = ketQua[khoaNganh] ?? [:]
            for item in khoi.danhSach {
                let nvKhop = Self.khopNhanVienQuetVoiQuanLy(
                    maQuet: item.maNV,
                    tenQuet: item.hoTen,
                    dsQuanLy: caiDat.danhSachNhanVien
                )
                let maLuu = nvKhop?.maNV ?? Self.chuanHoaMaNV(item.maNV)
                guard !maLuu.isEmpty else { continue }
                if item.thucHien >= 0 {
                    bangCu[maLuu] = item.thucHien
                }
            }
            ketQua[khoaNganh] = bangCu
        }
        return ketQua
    }

    static func apDungLocTuCaiDat(_ tenGoc: String) -> String {
        khoaBoNhoDemTinh.lock()
        if let daDem = boNhoDemLocTen[tenGoc] {
            khoaBoNhoDemTinh.unlock()
            return daDem
        }
        khoaBoNhoDemTinh.unlock()

        var s = tenGoc
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "^[\\s\\-–—−•◦○●⊕⊖|¦/\\\\,:;]+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "(?:\\s+|\\s*[\\|¦]\\s*)\\b(DT|SL|5L|0T)\\b\\s*$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.\\.\\.|…", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let danhSachLoc = KhoDuLieu.dungChung.caiDat.danhSachCumTuLocBo
        for cumTu in danhSachLoc {
            let sach = cumTu.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sach.isEmpty else { continue }
            s = s.replacingOccurrences(of: sach, with: "", options: .caseInsensitive)
        }

        s = s
            .replacingOccurrences(of: "^[\\s\\|¦\\-–—−•◦○●⊕⊖/\\\\.:;,…]+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[\\s\\|¦\\-–—−•◦○●⊕⊖/\\\\.:;,…]+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\|\\s*\\|+", with: "|", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let ketQua = s.isEmpty ? tenGoc.trimmingCharacters(in: .whitespacesAndNewlines) : s

        khoaBoNhoDemTinh.lock()
        boNhoDemLocTen[tenGoc] = ketQua
        khoaBoNhoDemTinh.unlock()
        return ketQua
    }

    static func gopDanhSachThiDua(cu: [DongThiDua], moi: [DongThiDua]) -> [DongThiDua] {
        var ketQua = cu
        for var dongMoi in moi {
            dongMoi.tenNganhHang = apDungLocTuCaiDat(dongMoi.tenNganhHangGoc)
            let khoaGocMoi = chuanHoaKhoaSoSanh(dongMoi.tenNganhHangGoc)
            let khoaMoi = khoaGocMoi.isEmpty ? chuanHoaKhoaSoSanh(dongMoi.tenNganhHang) : khoaGocMoi
            guard !khoaMoi.isEmpty else { continue }

            if let viTri = ketQua.firstIndex(where: {
                let kg = chuanHoaKhoaSoSanh($0.tenNganhHangGoc)
                return (kg.isEmpty ? chuanHoaKhoaSoSanh($0.tenNganhHang) : kg) == khoaMoi
            }) {
                var dongCu = ketQua[viTri]
                if dongMoi.tenNganhHangGoc.count > dongCu.tenNganhHangGoc.count && !dongMoi.tenNganhHangGoc.hasSuffix("...") {
                    dongCu.tenNganhHangGoc = dongMoi.tenNganhHangGoc
                    dongCu.tenNganhHang = dongMoi.tenNganhHang
                }
                dongCu.loaiChiTieu = dongMoi.loaiChiTieu
                if dongMoi.thucHien > 0 {
                    dongCu.thucHien = dongMoi.thucHien
                }
                if dongMoi.target > 0 {
                    dongCu.target = dongMoi.target
                }
                if let htGoc = dongMoi.phanTramHTGoc, htGoc > 0 {
                    dongCu.phanTramHTGoc = htGoc
                }
                if let dbGoc = dongMoi.phanTramDuBaoGoc, dbGoc > 0 {
                    dongCu.phanTramDuBaoGoc = dbGoc
                }
                if let dkGoc = dongMoi.duKienGoc, dkGoc > 0 {
                    dongCu.duKienGoc = dkGoc
                }
                ketQua[viTri] = dongCu
            } else {
                ketQua.append(dongMoi)
            }
        }
        return ketQua
    }

    static func chuanHoaKhoaSoSanh(_ ten: String) -> String {
        khoaBoNhoDemTinh.lock()
        if let daDem = boNhoDemKhoaSoSanh[ten] {
            khoaBoNhoDemTinh.unlock()
            return daDem
        }
        khoaBoNhoDemTinh.unlock()

        let ketQua = ten.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
            .replacingOccurrences(of: "[\\|¦\\-–—−•◦○●⊕⊖/\\\\.:;,…]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        khoaBoNhoDemTinh.lock()
        boNhoDemKhoaSoSanh[ten] = ketQua
        khoaBoNhoDemTinh.unlock()
        return ketQua
    }

    static func chuanHoaMaNV(_ raw: String) -> String {
        if let range = raw.range(of: "\\b\\d{3,10}\\b", options: .regularExpression) {
            return String(raw[range])
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func khopNhanVienQuetVoiQuanLy(
        maQuet: String,
        tenQuet: String,
        dsQuanLy: [NhanVienQuanLy]
    ) -> NhanVienQuanLy? {
        let maSach = chuanHoaMaNV(maQuet.isEmpty ? tenQuet : maQuet)
        if !maSach.isEmpty {
            if let theoMa = dsQuanLy.first(where: { $0.maNV == maSach }) {
                return theoMa
            }
            if dsQuanLy.contains(where: { !$0.maNV.isEmpty }) {
                return nil
            }
        }
        let tenKhongSo = tenQuet
            .replacingOccurrences(of: "\\d+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[-–—]", with: " ", options: .regularExpression)
        let tenChuan = chuanHoaKhoaSoSanh(tenKhongSo)
        guard !tenChuan.isEmpty else { return nil }

        for nv in dsQuanLy {
            let nvChuan = chuanHoaKhoaSoSanh(nv.hoTen)
            if nvChuan == tenChuan || nvChuan.hasSuffix(tenChuan) || tenChuan.hasSuffix(nvChuan) || nvChuan.contains(tenChuan) {
                return nv
            }
        }
        return nil
    }

    static func huyChuongHang(_ hang: Int) -> String {
        switch hang {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(hang)"
        }
    }

    /// Phân tích Sức khỏe Nhân viên toàn đội (~16 NV) và phát hiện Top 5 nhân viên yếu nhiều ngày liên tục
    func tinhBaoCaoSucKhoeNhanVien(
        den ngay: Date,
        cheDo: LoaiCheDoDoanhThu = .luyKe
    ) -> BaoCaoSucKhoeDoiNgu {
        khoaTruyCap.lock()
        defer { khoaTruyCap.unlock() }

        let dsNV = caiDat.danhSachNhanVien
        guard !dsNV.isEmpty else {
            return BaoCaoSucKhoeDoiNgu(
                ngayBaoCao: ngay,
                cheDo: cheDo,
                soNgayDaTheoDoi: 0,
                cacNhanNgayTheoDoi: [],
                soNVKhoe: 0,
                soNVTrungBinh: 0,
                soNVYeu: 0,
                diemTrungBinhDoiNgu: 0,
                top5CanhBaoYeu: [],
                danhSachTatCa: []
            )
        }

        let khoaDen = TienIchNgay.khoa.string(from: ngay)
        let tienToThang = String(khoaDen.prefix(7))

        // Lấy các ngày trong tháng hiện tại (và tối đa 10 ngày cuối tháng trước nếu đầu tháng) có dữ liệu nhân viên
        var cacKhoaUngVien = cacNgay.keys.filter { $0 <= khoaDen && $0.hasPrefix(tienToThang) }.sorted()
        if cacKhoaUngVien.count < 7 {
            let cacKhoaTruoc = cacNgay.keys.filter { $0 < khoaDen && !$0.hasPrefix(tienToThang) }.sorted().suffix(10)
            cacKhoaUngVien = Array(cacKhoaTruoc) + cacKhoaUngVien
        }
        if !cacKhoaUngVien.contains(khoaDen) {
            cacKhoaUngVien.append(khoaDen)
        }

        struct BanGhiNgay {
            let khoaNgay: String
            let ngayTrongThang: Int
            let nhanNgay: String
            let bangDiem: [String: DiemSucKhoeNgayNV]
        }

        var cacBanGhiNgay: [BanGhiNgay] = []

        for khoa in cacKhoaUngVien {
            guard let ngayD = TienIchNgay.khoa.date(from: khoa) else { continue }
            let dlRaw = cacNgay[khoa]
            let coDuLieuRiengNgay: Bool
            if let dlRaw {
                coDuLieuRiengNgay = !dlRaw.thiDuaNhanVien.isEmpty
                    || !dlRaw.thiDuaNhanVienRealtime.isEmpty
                    || !dlRaw.doanhThuNhanVienRealtime.isEmpty
                    || !dlRaw.danhSachThiDua.isEmpty
                    || !dlRaw.danhSachThiDuaRealtime.isEmpty
                    || (khoa == khoaDen && !dlRaw.doanhThuNhanVien.isEmpty)
            } else {
                coDuLieuRiengNgay = (khoa == khoaDen)
            }
            guard coDuLieuRiengNgay else { continue }

            // Chọn chế độ có dữ liệu thực tế cho ngày đó (ưu tiên cheDo đang chọn, nếu trống thì lấy chế độ còn lại)
            var dsTH = tongHopNhanVien(den: ngayD, sapXep: .soMonHoanThanh, cheDo: cheDo)
            let coSoChinh = dsTH.contains { $0.tongMonGiao > 0 || $0.doanhThuQD > 0 || $0.soMonDat > 0 }
            if !coSoChinh {
                let cheDoPhu: LoaiCheDoDoanhThu = (cheDo == .luyKe) ? .realtime : .luyKe
                let dsPhu = tongHopNhanVien(den: ngayD, sapXep: .soMonHoanThanh, cheDo: cheDoPhu)
                if dsPhu.contains(where: { $0.tongMonGiao > 0 || $0.doanhThuQD > 0 || $0.soMonDat > 0 }) {
                    dsTH = dsPhu
                } else if khoa != khoaDen {
                    continue
                }
            }

            let coThiDua = dsTH.contains { $0.tongMonGiao > 0 }
            let dsCoDT = dsTH.filter { $0.doanhThuQD > 0 }
            let coDoanhThu = !dsCoDT.isEmpty
            let tbHTTB = dsTH.map(\.phanTramHTTB).reduce(0.0, +) / Double(max(1, dsTH.count))
            let tbDTQD = coDoanhThu ? (dsCoDT.map(\.doanhThuQD).reduce(0.0, +) / Double(dsCoDT.count)) : 0

            var diemTamTheoMa: [String: (diem: Double, th: TongHopNhanVien)] = [:]
            for th in dsTH {
                let tyLeMon = th.tongMonGiao > 0 ? (Double(th.soMonDat) / Double(th.tongMonGiao)) * 100.0 : 0
                let diemHTTuyetDoi = min(100.0, th.phanTramHTTB)
                let diemHTTuongDoi = tbHTTB > 0.01 ? min(100.0, (th.phanTramHTTB / tbHTTB) * 72.0) : diemHTTuyetDoi
                let diemThiDua = 0.35 * tyLeMon + 0.30 * diemHTTuyetDoi + 0.35 * diemHTTuongDoi

                let diemDT: Double
                if coDoanhThu && tbDTQD > 0 {
                    diemDT = min(100.0, max(0.0, (th.doanhThuQD / tbDTQD) * 74.0))
                } else {
                    diemDT = 0
                }

                let diemTong: Double
                if coThiDua && coDoanhThu {
                    diemTong = 0.65 * diemThiDua + 0.35 * diemDT
                } else if coThiDua {
                    diemTong = diemThiDua
                } else if coDoanhThu {
                    diemTong = diemDT
                } else {
                    diemTong = 0
                }

                let diemChuan = min(100.0, max(0.0, diemTong))
                diemTamTheoMa[th.nhanVien.maNV] = (diemChuan, th)
            }

            let cacDiemSapXep = diemTamTheoMa.values.map(\.diem).sorted()
            let chiSoTop5Yeu = min(4, max(0, cacDiemSapXep.count - 1))
            let nguongTop5Yeu = cacDiemSapXep.isEmpty ? 55.0 : cacDiemSapXep[chiSoTop5Yeu]
            let coDuLieuThucTe = coThiDua || coDoanhThu

            let dNgay = TienIchNgay.lich.component(.day, from: ngayD)
            let mThang = TienIchNgay.lich.component(.month, from: ngayD)
            let nhanNgay = String(format: "%02d/%02d", dNgay, mThang)

            var bangDiemNgay: [String: DiemSucKhoeNgayNV] = [:]
            for nv in dsNV {
                guard let info = diemTamTheoMa[nv.maNV] else { continue }
                let mucDo: MucDoSucKhoeNV
                if !coDuLieuThucTe {
                    mucDo = .chuaCoSo
                } else if info.diem < 55.0 || (info.diem <= nguongTop5Yeu + 0.001 && info.diem < 74.0 && !(info.th.tongMonGiao > 0 && info.th.soMonDat == info.th.tongMonGiao)) {
                    mucDo = .yeu
                } else if info.diem >= 75.0 || (info.th.tongMonGiao > 0 && info.th.soMonDat == info.th.tongMonGiao) {
                    mucDo = .khoe
                } else {
                    mucDo = .trungBinh
                }

                bangDiemNgay[nv.maNV] = DiemSucKhoeNgayNV(
                    khoaNgay: khoa,
                    ngayTrongThang: dNgay,
                    nhanNgay: nhanNgay,
                    diemSucKhoe: info.diem,
                    mucDo: mucDo,
                    soMonDat: info.th.soMonDat,
                    tongMonGiao: info.th.tongMonGiao,
                    phanTramHTTB: info.th.phanTramHTTB,
                    doanhThuQD: info.th.doanhThuQD
                )
            }
            if coDuLieuThucTe || cacBanGhiNgay.isEmpty {
                cacBanGhiNgay.append(BanGhiNgay(
                    khoaNgay: khoa,
                    ngayTrongThang: dNgay,
                    nhanNgay: nhanNgay,
                    bangDiem: bangDiemNgay
                ))
            }
        }

        var dsTongHopHienTai = tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: cheDo)
        if !dsTongHopHienTai.contains(where: { $0.tongMonGiao > 0 || $0.doanhThuQD > 0 }) {
            let cheDoPhu: LoaiCheDoDoanhThu = (cheDo == .luyKe) ? .realtime : .luyKe
            let dsPhu = tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: cheDoPhu)
            if dsPhu.contains(where: { $0.tongMonGiao > 0 || $0.doanhThuQD > 0 }) {
                dsTongHopHienTai = dsPhu
            }
        }
        let mapTHHienTai = Dictionary(uniqueKeysWithValues: dsTongHopHienTai.map { ($0.nhanVien.maNV, $0) })

        var hoSoTam: [HoSoSucKhoeNhanVien] = []
        hoSoTam.reserveCapacity(dsNV.count)

        for nv in dsNV {
            let thHienTai = mapTHHienTai[nv.maNV] ?? TongHopNhanVien(
                nhanVien: nv,
                soMonDat: 0,
                tongMonGiao: 0,
                phanTramHTTB: 0,
                doanhThuQD: 0,
                soLuongDon: 0,
                phanTramTyTrong: 0,
                cacMonGiao: [],
                doanhThuCaNhan: nil
            )

            let lichSuDayDu: [DiemSucKhoeNgayNV] = cacBanGhiNgay.compactMap { $0.bangDiem[nv.maNV] }
            let lichSuCoSo = lichSuDayDu.filter { $0.mucDo != .chuaCoSo }

            var soNgayYeuLienTuc = 0
            for item in lichSuCoSo.reversed() {
                if item.mucDo == .yeu {
                    soNgayYeuLienTuc += 1
                } else {
                    break
                }
            }

            var chuoiYeuDaiNhat = 0
            var demTam = 0
            var tongSoNgayYeu = 0
            for item in lichSuCoSo {
                if item.mucDo == .yeu {
                    demTam += 1
                    tongSoNgayYeu += 1
                    chuoiYeuDaiNhat = max(chuoiYeuDaiNhat, demTam)
                } else {
                    demTam = 0
                }
            }

            let diemHienTai = lichSuDayDu.last?.diemSucKhoe ?? 0
            let mucDoHienTai = lichSuDayDu.last?.mucDo ?? .chuaCoSo

            let xuHuong: Double
            if lichSuCoSo.count >= 2 {
                let diemCuoi = lichSuCoSo.last!.diemSucKhoe
                let cacTruoc = lichSuCoSo.dropLast().suffix(3)
                let tbTruoc = cacTruoc.map(\.diemSucKhoe).reduce(0.0, +) / Double(max(1, cacTruoc.count))
                xuHuong = diemCuoi - tbTruoc
            } else {
                xuHuong = 0
            }

            let cacMonChuaDat = thHienTai.cacMonGiao
                .filter { !$0.daDat }
                .sorted { $0.phanTramHT < $1.phanTramHT }
                .prefix(2)
                .map { "\($0.tenNganhHang) (\(Int(round($0.phanTramHT)))%)" }

            hoSoTam.append(HoSoSucKhoeNhanVien(
                nhanVien: nv,
                tongHopHienTai: thHienTai,
                diemSucKhoe: diemHienTai,
                mucDo: mucDoHienTai,
                soNgayYeuLienTuc: soNgayYeuLienTuc,
                chuoiYeuDaiNhat: max(chuoiYeuDaiNhat, soNgayYeuLienTuc),
                tongSoNgayYeu: tongSoNgayYeu,
                tongSoNgayCoSo: lichSuCoSo.count,
                lichSuNgay: Array(lichSuDayDu.suffix(8)),
                cacMonYeuNhat: Array(cacMonChuaDat),
                xuHuongDiem: xuHuong,
                laCanhBaoTop5: false,
                hangCanhBao: nil
            ))
        }

        // Xác định 5 nhân viên yếu nhiều ngày liên tục nhất (ưu tiên số ngày yếu liên tục giảm dần -> tổng ngày yếu -> điểm sức khỏe thấp nhất)
        let sapXepCanhBao = hoSoTam.sorted { a, b in
            let aCoYeu = (a.soNgayYeuLienTuc > 0 || a.mucDo == .yeu) ? 1 : 0
            let bCoYeu = (b.soNgayYeuLienTuc > 0 || b.mucDo == .yeu) ? 1 : 0
            if aCoYeu != bCoYeu { return aCoYeu > bCoYeu }
            if a.soNgayYeuLienTuc != b.soNgayYeuLienTuc { return a.soNgayYeuLienTuc > b.soNgayYeuLienTuc }
            if a.tongSoNgayYeu != b.tongSoNgayYeu { return a.tongSoNgayYeu > b.tongSoNgayYeu }
            if abs(a.diemSucKhoe - b.diemSucKhoe) > 0.05 { return a.diemSucKhoe < b.diemSucKhoe }
            if abs(a.tongHopHienTai.phanTramHTTB - b.tongHopHienTai.phanTramHTTB) > 0.05 {
                return a.tongHopHienTai.phanTramHTTB < b.tongHopHienTai.phanTramHTTB
            }
            return a.tongHopHienTai.doanhThuQD < b.tongHopHienTai.doanhThuQD
        }

        let soLuongCanhBao = min(5, sapXepCanhBao.count)
        let maTop5 = Array(sapXepCanhBao.prefix(soLuongCanhBao).map(\.nhanVien.maNV))

        for i in hoSoTam.indices {
            if let viTri = maTop5.firstIndex(of: hoSoTam[i].nhanVien.maNV) {
                hoSoTam[i].laCanhBaoTop5 = true
                hoSoTam[i].hangCanhBao = viTri + 1
            }
        }

        let top5 = maTop5.compactMap { ma in hoSoTam.first(where: { $0.nhanVien.maNV == ma }) }
        let soKhoe = hoSoTam.filter { $0.mucDo == .khoe }.count
        let soTB = hoSoTam.filter { $0.mucDo == .trungBinh }.count
        let soYeu = hoSoTam.filter { $0.mucDo == .yeu }.count
        let diemTBDoi = hoSoTam.isEmpty ? 0 : (hoSoTam.map(\.diemSucKhoe).reduce(0.0, +) / Double(hoSoTam.count))
        let cacNhanNgay = cacBanGhiNgay.suffix(8).map(\.nhanNgay)
        let soNgayCoSo = cacBanGhiNgay.filter { bg in bg.bangDiem.values.contains(where: { $0.mucDo != .chuaCoSo }) }.count

        return BaoCaoSucKhoeDoiNgu(
            ngayBaoCao: ngay,
            cheDo: cheDo,
            soNgayDaTheoDoi: max(soNgayCoSo, cacBanGhiNgay.isEmpty ? 0 : 1),
            cacNhanNgayTheoDoi: Array(cacNhanNgay),
            soNVKhoe: soKhoe,
            soNVTrungBinh: soTB,
            soNVYeu: soYeu,
            diemTrungBinhDoiNgu: diemTBDoi,
            top5CanhBaoYeu: top5,
            danhSachTatCa: hoSoTam
        )
    }
}

// MARK: - Hộp Chọn Hành Động Tùy Chỉnh (Đảm bảo mọi dòng chữ có CÙNG CỠ CHỮ, tự động xuống dòng khi dài, tuyệt đối không bao giờ hiện dấu "...")

struct MucChonDMX {
    enum KieuMuc {
        case macDinh
        case nguyHiem
        case huy
    }

    let tieuDe: String
    let kieu: KieuMuc
    let dangChon: Bool
    let xuLy: (() -> Void)?

    init(tieuDe: String, kieu: KieuMuc = .macDinh, dangChon: Bool = false, xuLy: (() -> Void)? = nil) {
        self.tieuDe = tieuDe
        self.kieu = kieu
        self.dangChon = dangChon
        self.xuLy = xuLy
    }
}

private final class NutHangMenuDMX: UIControl {
    private let nhan = UILabel()
    private var xuLyBam: (() -> Void)?

    init(muc: MucChonDMX, coChu: UIFont, canGiua: Bool, khiBam: @escaping () -> Void) {
        self.xuLyBam = khiBam
        super.init(frame: .zero)
        backgroundColor = .clear

        let chuHienThi = muc.dangChon ? "✓  \(muc.tieuDe)" : muc.tieuDe
        nhan.text = chuHienThi
        nhan.font = coChu
        nhan.numberOfLines = 0
        nhan.lineBreakMode = .byWordWrapping
        nhan.adjustsFontSizeToFitWidth = false
        nhan.textAlignment = canGiua ? .center : .left

        switch muc.kieu {
        case .nguyHiem:
            nhan.textColor = .systemRed
        case .huy:
            nhan.textColor = .systemBlue
        case .macDinh:
            nhan.textColor = .systemBlue
        }

        nhan.translatesAutoresizingMaskIntoConstraints = false
        nhan.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(nhan)

        NSLayoutConstraint.activate([
            nhan.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            nhan.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13),
            nhan.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            nhan.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])

        addTarget(self, action: #selector(bamChon), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.label.withAlphaComponent(0.08) : .clear
        }
    }

    @objc private func bamChon() {
        xuLyBam?()
    }
}

final class HopChonDMXController: UIViewController {
    private let tieuDeMenu: String?
    private let thongDiepMenu: String?
    private let cacMuc: [MucChonDMX]
    private let canGiuaText: Bool

    private let nenMo = UIControl()
    private let khungChinh = UIView()
    private let khungDanhSach = UIView()
    private let khungNutHuy = UIView()

    init(tieuDe: String?, thongDiep: String? = nil, cacMuc: [MucChonDMX], canGiuaText: Bool = false) {
        self.tieuDeMenu = tieuDe
        self.thongDiepMenu = thongDiep
        self.cacMuc = cacMuc
        self.canGiuaText = canGiuaText
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("Khong ho tro coder")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        taoGiaoDien()
    }

    private func taoGiaoDien() {
        view.backgroundColor = .clear

        nenMo.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        nenMo.addTarget(self, action: #selector(bamDong), for: .touchUpInside)
        nenMo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nenMo)

        khungChinh.backgroundColor = .clear
        khungChinh.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(khungChinh)

        khungDanhSach.backgroundColor = .secondarySystemGroupedBackground
        khungDanhSach.layer.cornerRadius = 16
        khungDanhSach.clipsToBounds = true
        khungDanhSach.translatesAutoresizingMaskIntoConstraints = false

        let cuon = UIScrollView()
        cuon.showsVerticalScrollIndicator = true
        cuon.alwaysBounceVertical = false
        cuon.translatesAutoresizingMaskIntoConstraints = false
        khungDanhSach.addSubview(cuon)

        let ngan = UIStackView()
        ngan.axis = .vertical
        ngan.spacing = 0
        ngan.translatesAutoresizingMaskIntoConstraints = false
        cuon.addSubview(ngan)

        let coTieuDe = !(tieuDeMenu ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let coThongDiep = !(thongDiepMenu ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if coTieuDe || coThongDiep {
            let khungHeader = UIView()
            let nganHeader = UIStackView()
            nganHeader.axis = .vertical
            nganHeader.spacing = 4
            nganHeader.translatesAutoresizingMaskIntoConstraints = false
            khungHeader.addSubview(nganHeader)

            if coTieuDe, let td = tieuDeMenu {
                let lbTieuDe = UILabel()
                lbTieuDe.text = td
                lbTieuDe.font = .systemFont(ofSize: 15, weight: .bold)
                lbTieuDe.textColor = .label
                lbTieuDe.textAlignment = .center
                lbTieuDe.numberOfLines = 0
                lbTieuDe.lineBreakMode = .byWordWrapping
                lbTieuDe.adjustsFontSizeToFitWidth = false
                nganHeader.addArrangedSubview(lbTieuDe)
            }

            if coThongDiep, let msg = thongDiepMenu {
                let lbMsg = UILabel()
                lbMsg.text = msg
                lbMsg.font = .systemFont(ofSize: 13.5, weight: .regular)
                lbMsg.textColor = .secondaryLabel
                lbMsg.textAlignment = .center
                lbMsg.numberOfLines = 0
                lbMsg.lineBreakMode = .byWordWrapping
                lbMsg.adjustsFontSizeToFitWidth = false
                nganHeader.addArrangedSubview(lbMsg)
            }

            NSLayoutConstraint.activate([
                nganHeader.topAnchor.constraint(equalTo: khungHeader.topAnchor, constant: 14),
                nganHeader.bottomAnchor.constraint(equalTo: khungHeader.bottomAnchor, constant: -12),
                nganHeader.leadingAnchor.constraint(equalTo: khungHeader.leadingAnchor, constant: 16),
                nganHeader.trailingAnchor.constraint(equalTo: khungHeader.trailingAnchor, constant: -16)
            ])
            ngan.addArrangedSubview(khungHeader)
        }

        // Tất cả các dòng lựa chọn đều dùng chung 1 cỡ chữ 15pt đồng nhất, tự xuống dòng khi dài
        let coChuDongNhat = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let cacMucChinh = cacMuc.filter { $0.kieu != .huy }
        let mucHuy = cacMuc.first(where: { $0.kieu == .huy }) ?? MucChonDMX(tieuDe: "Đóng", kieu: .huy)

        for (idx, muc) in cacMucChinh.enumerated() {
            if idx > 0 || coTieuDe || coThongDiep {
                let vach = UIView()
                vach.backgroundColor = .separator
                vach.translatesAutoresizingMaskIntoConstraints = false
                vach.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                ngan.addArrangedSubview(vach)
            }

            let nut = NutHangMenuDMX(muc: muc, coChu: coChuDongNhat, canGiua: canGiuaText) { [weak self] in
                guard let self else { return }
                self.dismiss(animated: true) {
                    muc.xuLy?()
                }
            }
            ngan.addArrangedSubview(nut)
        }

        khungNutHuy.backgroundColor = .secondarySystemGroupedBackground
        khungNutHuy.layer.cornerRadius = 16
        khungNutHuy.clipsToBounds = true
        khungNutHuy.translatesAutoresizingMaskIntoConstraints = false

        let nutHuy = NutHangMenuDMX(
            muc: mucHuy,
            coChu: .systemFont(ofSize: 16, weight: .bold),
            canGiua: true
        ) { [weak self] in
            guard let self else { return }
            self.dismiss(animated: true) {
                mucHuy.xuLy?()
            }
        }
        nutHuy.translatesAutoresizingMaskIntoConstraints = false
        khungNutHuy.addSubview(nutHuy)

        khungChinh.addSubview(khungDanhSach)
        khungChinh.addSubview(khungNutHuy)

        let chieuCaoCuon = cuon.heightAnchor.constraint(equalTo: ngan.heightAnchor)
        chieuCaoCuon.priority = .defaultHigh

        NSLayoutConstraint.activate([
            nenMo.topAnchor.constraint(equalTo: view.topAnchor),
            nenMo.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            nenMo.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            nenMo.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            khungChinh.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            khungChinh.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),
            khungChinh.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            khungChinh.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),

            khungDanhSach.topAnchor.constraint(equalTo: khungChinh.topAnchor),
            khungDanhSach.leadingAnchor.constraint(equalTo: khungChinh.leadingAnchor),
            khungDanhSach.trailingAnchor.constraint(equalTo: khungChinh.trailingAnchor),

            cuon.topAnchor.constraint(equalTo: khungDanhSach.topAnchor),
            cuon.leadingAnchor.constraint(equalTo: khungDanhSach.leadingAnchor),
            cuon.trailingAnchor.constraint(equalTo: khungDanhSach.trailingAnchor),
            cuon.bottomAnchor.constraint(equalTo: khungDanhSach.bottomAnchor),
            chieuCaoCuon,

            ngan.topAnchor.constraint(equalTo: cuon.contentLayoutGuide.topAnchor),
            ngan.leadingAnchor.constraint(equalTo: cuon.contentLayoutGuide.leadingAnchor),
            ngan.trailingAnchor.constraint(equalTo: cuon.contentLayoutGuide.trailingAnchor),
            ngan.bottomAnchor.constraint(equalTo: cuon.contentLayoutGuide.bottomAnchor),
            ngan.widthAnchor.constraint(equalTo: cuon.frameLayoutGuide.widthAnchor),

            khungNutHuy.topAnchor.constraint(equalTo: khungDanhSach.bottomAnchor, constant: 8),
            khungNutHuy.leadingAnchor.constraint(equalTo: khungChinh.leadingAnchor),
            khungNutHuy.trailingAnchor.constraint(equalTo: khungChinh.trailingAnchor),
            khungNutHuy.bottomAnchor.constraint(equalTo: khungChinh.bottomAnchor),

            nutHuy.topAnchor.constraint(equalTo: khungNutHuy.topAnchor),
            nutHuy.leadingAnchor.constraint(equalTo: khungNutHuy.leadingAnchor),
            nutHuy.trailingAnchor.constraint(equalTo: khungNutHuy.trailingAnchor),
            nutHuy.bottomAnchor.constraint(equalTo: khungNutHuy.bottomAnchor)
        ])
    }

    @objc private func bamDong() {
        let mucHuy = cacMuc.first(where: { $0.kieu == .huy })
        dismiss(animated: true) {
            mucHuy?.xuLy?()
        }
    }
}

extension UIViewController {
    func hienMenuChon(
        tieuDe: String? = nil,
        thongDiep: String? = nil,
        cacMuc: [MucChonDMX],
        canGiuaText: Bool = false
    ) {
        let hop = HopChonDMXController(
            tieuDe: tieuDe,
            thongDiep: thongDiep,
            cacMuc: cacMuc,
            canGiuaText: canGiuaText
        )
        present(hop, animated: true)
    }
}

extension UIView {
    /// Đảm bảo mọi UILabel và UIButton bên trong view luôn hiển thị trọn vẹn văn bản, tự xuống dòng, không bao giờ hiện dấu "..."
    func damBaoHienThiDayDuText() {
        if let lb = self as? UILabel {
            lb.numberOfLines = 0
            lb.lineBreakMode = .byWordWrapping
            lb.adjustsFontSizeToFitWidth = false
        } else if let bt = self as? UIButton {
            bt.titleLabel?.numberOfLines = 0
            bt.titleLabel?.lineBreakMode = .byWordWrapping
            bt.titleLabel?.adjustsFontSizeToFitWidth = false
        }
        for sub in subviews {
            sub.damBaoHienThiDayDuText()
        }
    }
}

extension UIAlertController {
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        view.damBaoHienThiDayDuText()
    }
}

enum TienIchNgay {
    static let lich: Calendar = {
        var lich = Calendar(identifier: .gregorian)
        lich.locale = Locale(identifier: "vi_VN")
        lich.timeZone = .current
        return lich
    }()

    static let khoa: DateFormatter = {
        let dinhDang = DateFormatter()
        dinhDang.calendar = lich
        dinhDang.locale = Locale(identifier: "vi_VN")
        dinhDang.dateFormat = "yyyy-MM-dd"
        return dinhDang
    }()

    static let hienThiNgay: DateFormatter = {
        let dinhDang = DateFormatter()
        dinhDang.calendar = lich
        dinhDang.locale = Locale(identifier: "vi_VN")
        dinhDang.dateFormat = "dd/MM/yyyy"
        return dinhDang
    }()

    static let hienThiGioPhut: DateFormatter = {
        let dinhDang = DateFormatter()
        dinhDang.calendar = lich
        dinhDang.locale = Locale(identifier: "vi_VN")
        dinhDang.dateFormat = "HH:mm dd/MM/yyyy"
        return dinhDang
    }()

    static func heSoDuBaoThang(cho ngay: Date = Date()) -> Double {
        let soNgayTrongThang = Double(lich.range(of: .day, in: .month, for: ngay)?.count ?? 30)
        let ngayHienTai = Double(max(1, lich.component(.day, from: ngay)))
        return max(1.0, soNgayTrongThang / ngayHienTai)
    }
}

extension Double {
    private static let boDinhDangVN: NumberFormatter = {
        let df = NumberFormatter()
        df.locale = Locale(identifier: "vi_VN")
        df.numberStyle = .decimal
        df.minimumFractionDigits = 2
        df.maximumFractionDigits = 2
        return df
    }()

    private static let boDinhDangNguyenVN: NumberFormatter = {
        let df = NumberFormatter()
        df.locale = Locale(identifier: "vi_VN")
        df.numberStyle = .decimal
        df.minimumFractionDigits = 0
        df.maximumFractionDigits = 0
        return df
    }()

    private static let boDinhDangSoLieuNguyenUS: NumberFormatter = {
        let df = NumberFormatter()
        df.locale = Locale(identifier: "en_US")
        df.numberStyle = .decimal
        df.minimumFractionDigits = 0
        df.maximumFractionDigits = 0
        return df
    }()

    private static let boDinhDangSoLieuThapPhanUS: NumberFormatter = {
        let df = NumberFormatter()
        df.locale = Locale(identifier: "en_US")
        df.numberStyle = .decimal
        df.minimumFractionDigits = 2
        df.maximumFractionDigits = 2
        return df
    }()

    var chuoiSoVN: String {
        Double.boDinhDangVN.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }

    var chuoiSoNguyenVN: String {
        Double.boDinhDangNguyenVN.string(from: NSNumber(value: self.rounded())) ?? String(format: "%.0f", self)
    }

    var chuoiSoGonVN: String {
        if abs(self.rounded() - self) < 0.005 {
            return chuoiSoNguyenVN
        }
        return chuoiSoVN
    }

    var chuoiPhanTramVN: String {
        "\(self.chuoiSoVN)%"
    }

    var chuoiSoLieu: String {
        if abs(self.rounded() - self) < 0.005 {
            return Double.boDinhDangSoLieuNguyenUS.string(from: NSNumber(value: self.rounded())) ?? String(format: "%.0f", self)
        }
        return Double.boDinhDangSoLieuThapPhanUS.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }

    var chuoiChenhLech: String {
        if abs(self) < 0.005 { return "0" }
        let dau = self > 0 ? "+" : ""
        return "\(dau)\(self.chuoiSoLieu)"
    }

    var chuoiPhanTram: String {
        if abs(self.rounded() - self) < 0.05 {
            return String(format: "%.0f%%", self)
        }
        return String(format: "%.1f%%", self)
    }
}
