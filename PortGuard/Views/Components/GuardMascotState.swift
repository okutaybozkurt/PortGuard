import Foundation

/// Guard maskotunun durumu. İfade yalnızca gözlerle ve ince bir ışık/halka efektiyle verilir.
public enum GuardMood: Equatable {
    case idle       // yavaş nefes + ara sıra göz kırpma
    case scanning   // gözler yatay kayar
    case alert      // turuncu/kırmızı gözler + nabız halkası
    case calm       // gözler ince çizgi
}
