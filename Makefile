TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CocCocGeminiSolver

CocCocGeminiSolver_FILES = Tweak.x
CocCocGeminiSolver_CFLAGS = -fobjc-arc
CocCocGeminiSolver_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
