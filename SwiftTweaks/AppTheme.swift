//
//  AppTheme.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 4/6/16.
//  Copyright © 2016 Khan Academy. All rights reserved.
//

import UIKit

/// Lets the host app give the Tweaks UI its own accent colour.
public enum TweaksAppearance {
	/// Tints the Tweaks UI's buttons, switches, steppers and icons. Set it before the Tweaks UI is first shown.
	///
	/// It does not tint the `TweakWindow` itself, which is usually the app's main window.
	public static var tintColor: UIColor = AppTheme.Colors.Palette.tintColor
}

/// A central "palette" so to help keep our design consistent.
internal struct AppTheme {
	struct Colors {
		struct Palette {
			static let whiteColor = UIColor.white
			static let blackColor = UIColor.black
			static let grayColor = UIColor(hex: 0x8E8E93)
			static let pageBackground1 = UIColor(hex: 0xF8F8F8)
			static let touchHighlight = UIColor(hex: 0xF2F2F2)

			static let tintColor = UIColor(hex: 0x007AFF)
			static let tintColorPressed = UIColor(hex: 0x084BC1)
			static let controlGrayscale = UIColor.darkGray

			static let secondaryControl = UIColor(hex: 0xC8C7CC)
			static let secondaryControlPressed = UIColor(hex: 0xAFAFB3)

			static let destructiveRed = UIColor(hex: 0xC90911)
		}

		static let sectionHeaderTitleColor = Palette.grayColor

		static let textPrimary = Palette.blackColor

		static var controlTinted: UIColor { TweaksAppearance.tintColor }
		/// A darker `controlTinted`, or the stock pressed blue while the tint is the stock blue.
		static var controlTintedPressed: UIColor {
			let tint = TweaksAppearance.tintColor
			var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
			guard tint != Palette.tintColor,
				  tint.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
				return Palette.tintColorPressed
			}
			return UIColor(hue: hue, saturation: saturation, brightness: brightness * 0.75, alpha: alpha)
		}
		/// The `TweakWindow`'s own tint. Deliberately not `controlTinted`: the window is usually the app's, and the
		/// Tweaks UI's accent colour should not repaint the app.
		static let windowTint = Palette.tintColor
		static let controlDisabled = Palette.secondaryControl
		static let controlDestructive = Palette.destructiveRed
		static let controlSecondary = Palette.secondaryControl
		static let controlSecondaryPressed = Palette.secondaryControlPressed
		static let controlGrayscale = Palette.controlGrayscale

		static let floatingTweakGroupNavBG = Palette.pageBackground1

		static let tableSeparator = Palette.secondaryControl
		static let tableCellTouchHighlight = Palette.touchHighlight

		static let debugRed = UIColor.red.withAlphaComponent(0.3)
		static let debugYellow = UIColor.yellow.withAlphaComponent(0.3)
		static let debugBlue = UIColor.blue.withAlphaComponent(0.3)

	}

	struct Fonts {
		static let sectionHeaderTitleFont: UIFont = .preferredFont(forTextStyle: UIFont.TextStyle.body)
	}

	struct Shadows {
		static let floatingShadowColor = Colors.Palette.blackColor.cgColor
		static let floatingShadowOpacity: Float = 0.6
		static let floatingShadowOffset = CGSize(width: 0, height: 1)
		static let floatingShadowRadius: CGFloat = 4

		static let floatingNavShadowColor = floatingShadowColor
		static let floatingNavShadowOpacity: Float = 0.1
		static let floatingNavShadowOffset = floatingShadowOffset
		static let floatingNavShadowRadius: CGFloat = 0
	}
}
