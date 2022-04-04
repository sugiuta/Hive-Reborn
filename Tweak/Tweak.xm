#import "headers/funcs.h"

// Var
static HBPreferences *preferences;
static SBUIPasscodeLockViewSimpleFixedDigitKeypad *lockView;
static NSMutableArray *oldBtns = [[NSMutableArray alloc] initWithCapacity:10];
static NSMutableArray *availableNos = [@[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9] mutableCopy];;
static BOOL dummyPassInstalled;
static BOOL scramblePassInstalled;
static BOOL hiveVisible;

// Preferences
static BOOL enabled;
static BOOL useUnlockAnime;
static NSString *separatorColorValue;
static NSString *labelColorValue;
static NSString *mainColorValue;
static CGFloat separatorColorAlpha;
static CGFloat labelColorAlpha;
static CGFloat mainColorAlpha;
static CGFloat animDuration;

@implementation HexagonView

    - (instancetype)initWithOrigin:(CGPoint)o width:(CGFloat)w {
        CGFloat h = heightForWidth(w); // heightForWidthはfuncs.hのインライン関数。
        CGRect frame = CGRectMake(o.x, o.y, w, h);
        self = [self initWithFrame:frame];
        if (self) {
            self.userInteractionEnabled = NO;
            //add observer for unlock animation, notifStr @"com.sugiuta.hivereborn-startUnlockAnimation"
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startUnlockAnimation) name:notifStr object:nil];
        }
        return self;
    }

    - (void)didMoveToWindow {
        [super didMoveToWindow];

        CAShapeLayer* shapeLayer = [CAShapeLayer layer]; // パスを利用して座標空間に描画ができる。例:円の描画
        _path = [UIBezierPath bezierPath]; // ベジェ曲線を利用して自由に曲線を描画できる。

        CGFloat w = self.frame.size.width;
        NSArray* points = pointsForWidth(w);

        [_path moveToPoint:[points[0] CGPointValue]]; // pathの初期位置
        for (int i = 1; i < 6; i++) {
            [_path addLineToPoint:[points[i] CGPointValue]]; // pointsの要素ごとの位置をpathに追加。
        }
        [_path closePath]; // 終了
        [shapeLayer setPath:[_path CGPath]];
        [shapeLayer setFillColor:[self.fillColor CGColor]]; // 後で色を指定できるように変更
        [shapeLayer setStrokeColor:[[UIColor pf_colorWithHexString:separatorColorValue alpha:separatorColorAlpha] CGColor]]; // 後で色を指定できるように変更
        [[self layer] addSublayer:shapeLayer]; // layerを追加。
    }

    - (void)startUnlockAnimation {
        CGPoint p = [self.superview isKindOfClass:[HexagonButton class]] ? self.superview.center : self.center;

        //get x and y as percentages
        float xPerc = p.x / W; // Wは画面の横のサイズを表している
        float yPerc = p.y / H; // Hは画面の縦のサイズを表している

        //distances from centre
        float xDist = fabs(0.5 - xPerc); // このままの計算だとマイナスが出てしまうのでfabsを用いて浮動小数点数の絶対値を取得
        float yDist = fabs(0.5 - yPerc);

        //pythag
        float dist = sqrt(xDist*xDist + yDist*yDist);
        CGFloat duration = (dist / sqrt(0.5)) * animDuration;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{
                [self.superview isKindOfClass:[HexagonButton class]] ? self.superview.alpha = 0 : self.alpha = 0;
            }];
        });
    }

@end

@implementation HexagonButton

    - (instancetype)initWithOrigin:(CGPoint)o width:(CGFloat)w {
        CGFloat h = heightForWidth(w);
        CGRect frame = CGRectMake(o.x, o.y, w, h);
        self = [self initWithFrame:frame];
        if (self) {
            hexagon = [[HexagonView alloc] initWithOrigin:CGPointMake(0, 0) width:w];
            [self addSubview:hexagon];
            numLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, h)]; // numLblはinterface.hで定義済みの変数
            numLbl.textColor = [UIColor pf_colorWithHexString:labelColorValue alpha:labelColorAlpha]; // 後で変更可能にする。
            numLbl.textAlignment = NSTextAlignmentCenter;
            numLbl.font = [numLbl.font fontWithSize:20];
            [self addSubview:numLbl];

            //add darkening view
            UIColor *darkeningColor = [UIColor colorWithWhite:0 alpha:0.3];
            darkeningView = [[HexagonView alloc] initWithOrigin:CGPointMake(0, 0) width:self.frame.size.width];
            darkeningView.fillColor = darkeningColor;
            darkeningView.alpha = 0;
            [self addSubview:darkeningView];
        }
        return self;
    }

    - (void)touchesBegan:(id)arg1 withEvent:(id)arg2 {
        [UIView animateWithDuration:0.1 animations:^{
            darkeningView.alpha = 1;
        }];

        //press button ここら辺問題なし
        SBPasscodeNumberPadButton *oldBtn = oldBtns[self.buttonNo];
        UIView *pad = [lockView _numberPad];
        [lockView passcodeLockNumberPad:pad keyDown:oldBtn];

        [super touchesBegan:arg1 withEvent:arg2];
    }

    - (void)touchesEnded:(id)arg1 withEvent:(id)arg2 {
        //remove darkening view
        [UIView animateWithDuration:0.1 animations:^{
            darkeningView.alpha = 0;
        }];

        //press button ここら辺問題なし
        SBPasscodeNumberPadButton *oldBtn = oldBtns[self.buttonNo];
        UIView *pad = [lockView _numberPad];
        [lockView passcodeLockNumberPad:pad keyUp:oldBtn];

        [super touchesEnded:arg1 withEvent:arg2];
    }

    - (void)setFillColor:(UIColor *)arg1 {
        hexagon.fillColor = arg1;
        _fillColor = arg1;
    }

    - (void)setButtonNo:(unsigned int)arg1 {
        unsigned int displayNo = (arg1 == 9 ? 0 : arg1+1);
        if (dummyPassInstalled || scramblePassInstalled) {
            NSInteger index = arc4random_uniform(availableNos.count);
            displayNo = [availableNos[index] integerValue];
            [availableNos removeObjectAtIndex:index];
        }
        numLbl.text = [NSString stringWithFormat:@"%d", displayNo];
        if (!scramblePassInstalled) _buttonNo = arg1;
        else _buttonNo = (displayNo == 0 ? 9 : displayNo-1);
    }

    //stop hexagon hit boxes from overlapping
    - (id)hitTest:(CGPoint)arg1 withEvent:(id)arg2 {
        if (CGPathContainsPoint([hexagon.path CGPath], NULL, arg1, NO)) {
            return [super hitTest:arg1 withEvent:arg2];
        }
        return nil;
    }

@end

%group Tweak

%hook CSPasscodeViewController
    - (void)viewWillAppear:(BOOL)arg1 {
        %orig;
        lockView = MSHookIvar<SBUIPasscodeLockViewSimpleFixedDigitKeypad*>(self, "_passcodeLockView");
    }

    - (void)viewDidDisappear:(BOOL)arg1 {
        %orig;
        hiveVisible = NO;
        availableNos = [@[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9] mutableCopy];
    }

    - (void)setUseBiometricPresentation:(BOOL)arg1 {
        return %orig(arg1 == NO);
    }
%end

%hook SBUIPasscodeLockViewSimpleFixedDigitKeypad
    - (void)didMoveToWindow {
        %orig;
        [self createHive:NO];
    }

    %new
    - (void)createHive:(BOOL)animated {
        hiveVisible = YES;

        /* Hide old keypad: */
        UIView *pad = MSHookIvar<UIView*>([self _numberPad], "_numberPad");
        pad.hidden = YES;

        /* Bring label forward: */
        UIView *titleView = self.statusTitleView.superview;
        titleView.layer.zPosition = 999;

        if (animated) self.alpha = 0;

        /* Create buttons: */
        UIColor *mainColor = [UIColor pf_colorWithHexString:mainColorValue alpha:mainColorAlpha];
        CGFloat firstY = pad.superview.frame.origin.y;
        CGFloat w = widthForStack(pad.frame.size.width, 3);
        CGPoint o1 = CGPointMake((self.frame.size.width - w) / 2, firstY);
        HexagonButton* h1 = [[HexagonButton alloc] initWithOrigin:o1 width:w];
        h1.fillColor = colorForHexagon(h1, mainColor);
        [self addSubview:h1];

        NSMutableArray <UIView*> *keypadButtons = [NSMutableArray new];
        NSArray <UIView*> *btns = createButtonsForBtn(h1, mainColor);
        [keypadButtons addObject:btns[0]];
        [keypadButtons addObject:h1];
        [keypadButtons addObject:btns[1]];

        btns = createButtonsUnderBtn(h1, mainColor);
        [keypadButtons addObjectsFromArray:btns];

        btns = createButtonsUnderBtn(btns[1], mainColor);
        [keypadButtons addObjectsFromArray:btns];

        CGPoint o0 = originForSide(keypadButtons[7], 4);
        HexagonButton* h0 = [[HexagonButton alloc] initWithOrigin:o0 width:w];
        h0.fillColor = colorForHexagon(h0, mainColor);
        [self addSubview:h0];
        [keypadButtons addObject:h0];

        //add button actions:
        for (int i = 0; i < keypadButtons.count; i++) {
            HexagonButton* btn = (HexagonButton*)keypadButtons[i];
            btn.buttonNo = i;
        }

        /* Create other hexagons: */
        //add above:
        CGFloat y = keypadButtons[0].frame.origin.y;
        UIView* lastCentre = keypadButtons[1];
        while (y > 0) {
            btns = createHexesAboveHex(lastCentre, mainColor);
            y = btns[0].frame.origin.y;
            lastCentre = btns[1];
        }

        //add below:
        CGPoint oL = originForSide(keypadButtons[9], 5);
        HexagonView* bL = [[HexagonView alloc] initWithOrigin:oL width:w];
        bL.fillColor = colorForHexagon(bL, mainColor);
        [self addSubview:bL];

        CGPoint oR = originForSide(keypadButtons[9], 3);
        HexagonView* bR = [[HexagonView alloc] initWithOrigin:oR width:w];
        bR.fillColor = colorForHexagon(bR, mainColor);
        [self addSubview:bR];

        y = keypadButtons[9].frame.origin.y + keypadButtons[9].frame.size.height;
        lastCentre = keypadButtons[9];
        while (y < self.frame.size.height) {
            btns = createHexesUnderHex(lastCentre, mainColor);
            y = btns[1].frame.origin.y + btns[1].frame.size.height;
            lastCentre = btns[1];
        }

        //add to sides:
        CGFloat h = heightForWidth(w);
        CGFloat leftX = originForSide(btns[0], 0).x;
        CGFloat rightX = originForSide(btns[2], 2).x;
        y = btns[1].frame.origin.y + h;
        while (y > 0) {
            y -= h;
            CGPoint leftO = CGPointMake(leftX, y);
            HexagonView* lHex = [[HexagonView alloc] initWithOrigin:leftO width:w];
            lHex.fillColor = colorForHexagon(lHex, mainColor);
            [self addSubview:lHex];

            CGPoint rightO = CGPointMake(rightX, y);
            HexagonView* rHex = [[HexagonView alloc] initWithOrigin:rightO width:w];
            rHex.fillColor = colorForHexagon(rHex, mainColor);
            [self addSubview:rHex];
        }

        if (animated) {
            [UIView animateWithDuration:0.3 animations:^{
                self.alpha = 1.f;
            }];
        }
    }
%end

%hook UILabel
    - (void)didMoveToWindow {
        %orig;
        if ([[self _viewControllerForAncestor] isKindOfClass:%c(CSPasscodeViewController)]) {
            UIView *titleView = lockView.statusTitleView;
            if (titleView == self) {
                self.textColor = [UIColor pf_colorWithHexString:labelColorValue alpha:labelColorAlpha];
            }
        }
    }
%end

%hook SBUIButton
    - (void)didMoveToWindow { // 緊急、キャンセルボタンの色変更
        %orig;
        #define self ((UIButton*)self)
        if ([[self _viewControllerForAncestor] isKindOfClass:%c(CSPasscodeViewController)]) {
            [self setTitleColor:[UIColor pf_colorWithHexString:labelColorValue alpha:labelColorAlpha] forState:UIControlStateNormal];
        }
        #undef self
    }
%end

%hook SBPasscodeNumberPadButton
    - (id)initForCharacter:(unsigned int)arg1 {
        self = %orig;
        if (arg1 == 10)
            arg1 = 9;
        oldBtns[arg1] = self;
        return self;
    }
%end

%hook SBCoverSheetSlidingViewController
    - (void)_dismissCoverSheetAnimated:(BOOL)arg1 withCompletion:(/*^block*/id)arg2 {
        if (hiveVisible && useUnlockAnime) {
            arg1 = NO;
            //start animation
            [[NSNotificationCenter defaultCenter] postNotificationName:notifStr object:nil];
            CGFloat padding = animDuration * 0.125;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (animDuration + padding) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                %orig;
            });
        } else {
            %orig;
        }
    }
%end

%end

%ctor {
    preferences = [[HBPreferences alloc] initWithIdentifier:@"com.sugiuta.hivereborn"];
    [preferences registerBool:&enabled default:NO forKey:@"kEnabled"];
    [preferences registerBool:&useUnlockAnime default:NO forKey:@"kUseUnlockAnime"];
    [preferences registerObject:&separatorColorValue default:@"#FFFFFF" forKey:@"kSeparatorColorValue"];
    [preferences registerFloat:&separatorColorAlpha default:1.0 forKey:@"kSeparatorColorAlpha"];
    [preferences registerObject:&labelColorValue default:@"#FFFFFF" forKey:@"kLabelColorValue"];
    [preferences registerFloat:&labelColorAlpha default:1.0 forKey:@"kLabelColorAlpha"];
    [preferences registerObject:&mainColorValue default:@"#FFFFFF" forKey:@"kMainColorValue"];
    [preferences registerFloat:&mainColorAlpha default:1.0 forKey:@"kMainColorAlpha"];
    [preferences registerFloat:&animDuration default:0.4 forKey:@"kAnimDuration"];

    if (enabled) %init(Tweak);
}
