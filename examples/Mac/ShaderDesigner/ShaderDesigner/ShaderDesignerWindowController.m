#import "ShaderDesignerWindowController.h"

NSString *const kGPUImageInitialVertexShaderString = @"attribute vec4 position;\nattribute vec4 inputTextureCoordinate;\n\nvarying vec2 textureCoordinate;\n\nvoid main()\n{\n\tgl_Position = position;\n\ttextureCoordinate = inputTextureCoordinate.xy;\n}\n";

NSString *const kGPUImageInitialFragmentShaderString = @"varying vec2 textureCoordinate;\n\nuniform sampler2D inputImageTexture;\n\nvoid main()\n{\n\tgl_FragColor = texture2D(inputImageTexture, textureCoordinate);\n}\n";


@interface ShaderDesignerWindowController ()

@end

@implementation ShaderDesignerWindowController

/*
 @property (weak) IBOutlet GPUImageView *previewView;
 @property (weak) IBOutlet GPUImageView *shaderOutputView;
 */

- (void) addShaderOutputVie {
    self.shaderOutputView  = [GPUImageView new];
    [self.shaderOutputView setFrame:
     CGRectMake(0, 0, self.shaderSupView.frame.size.width, self.shaderSupView.frame.size.height)];
    
    [self.shaderSupView addSubview:self.shaderOutputView];
    
    if (self.previewView != nil) {
        [inputCamera removeTarget:self.previewView];
        [self.previewView removeFromSuperview];
        self.previewView = nil;
    }
    [inputCamera addTarget:self.shaderOutputView];
    
    
}

- (void) addShaderPreview {
    self.previewView  = [GPUImageView new];
    [self.previewView setFrame:
     CGRectMake(0, 0, self.previewSup.frame.size.width, self.previewSup.frame.size.height)];
    
    [self.previewSup addSubview:self.previewView];
    
    if (self.shaderOutputView != nil) {
        [inputCamera removeTarget:self.shaderOutputView];
        [self.shaderOutputView removeFromSuperview];
        self.shaderOutputView = nil;
    }
    
    [inputCamera addTarget:self.previewView];
    self.previewView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    inputCamera = [[GPUImageAVCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraDevice:nil];
//    inputCamera.runBenchmark = YES;

    self.vertexShader = kGPUImageInitialVertexShaderString;
    self.fragmentShader = kGPUImageInitialFragmentShaderString;
    self.previewView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
//    [inputCamera addTarget:self.previewView];
//    self.previewView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;

    [inputCamera startCameraCapture];
    self.shaderOutputView = nil;
    
//    [self addShaderOutputVie];
    [self addShaderPreview];

    [self compile:self];
}

- (IBAction)compile:(id)sender;
{
    [self.window makeFirstResponder:nil];
    // Test compilation first, see if it will work
    __block BOOL compilationFailed = NO;
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        GLProgram *filterProgram = [[GLProgram alloc] initWithVertexShaderString:self.vertexShader fragmentShaderString:self.fragmentShader];
        
        if (!filterProgram.initialized)
        {
            if (![filterProgram link])
            {
                compilationFailed = YES;
                [self.displayTabView selectTabViewItem:self.logTabItem];
                self.compileLog = [NSString stringWithFormat:@"Vertex shader log:\n%@\n\nFragment shader log:\n%@\n\nProgram log:\n%@\n\n", [filterProgram programLog], [filterProgram fragmentShaderLog], [filterProgram vertexShaderLog]];
            }
        }
    });
    if (compilationFailed)
    {
        return;
    }

    [self.displayTabView selectTabViewItem:self.displayTabItem];
    
    if (self.shaderOutputView != nil) {
        [inputCamera pauseCameraCapture];
        if (testFilter != nil)
        {
            [inputCamera removeTarget:testFilter];
            [testFilter removeTarget:self.shaderOutputView];
        }
        testFilter = [[GPUImageFilter alloc] initWithVertexShaderFromString:self.vertexShader fragmentShaderFromString:self.fragmentShader];

        [inputCamera addTarget:testFilter];
        [testFilter addTarget:self.shaderOutputView];
    }
    
//    NSLog(@"previewView ===> %f, %f", self.previewView.frame.origin.y, self.previewView.frame.origin.y);
//    NSLog(@"shaderOutputView ===> %f, %f", self.shaderOutputView.frame.origin.y, self.shaderOutputView.frame.origin.y);

    [inputCamera resumeCameraCapture];
}

- (IBAction)switchView:(id)sender {
    NSLog(@"switch click");
    if (self.shaderOutputView == nil) {
        [self addShaderOutputVie];
    } else {
        [self addShaderPreview];
    }
}

#pragma mark -
#pragma mark File loading / saving

- (IBAction)openVertexShader:(id)sender;
{
    NSOpenPanel *shaderLoadingDialog = [NSOpenPanel openPanel];
    [shaderLoadingDialog setAllowedFileTypes:[NSArray arrayWithObjects:@"vsh", @"txt", nil]];
    
    if ( [shaderLoadingDialog runModal] == NSModalResponseOK )
    {
        NSError *error = nil;
        NSString *fileContents = [NSString stringWithContentsOfURL:[shaderLoadingDialog URL] encoding:NSASCIIStringEncoding error:&error];
        if (fileContents == nil)
        {
            if (error == nil)
            {
                NSLog(@"Don't have an error to present for failing to save topography map");
            }
            
            [NSApp presentError:error];
        }
        else
        {
            self.vertexShader = fileContents;
        }
    }
}

- (IBAction)openFragmentShader:(id)sender;
{
    NSOpenPanel *shaderLoadingDialog = [NSOpenPanel openPanel];
    [shaderLoadingDialog setAllowedFileTypes:[NSArray arrayWithObjects:@"fsh", @"txt", nil]];
    
    if ( [shaderLoadingDialog runModal] == NSModalResponseOK )
    {
        NSError *error = nil;
        NSString *fileContents = [NSString stringWithContentsOfURL:[shaderLoadingDialog URL] encoding:NSASCIIStringEncoding error:&error];
        if (fileContents == nil)
        {
            if (error == nil)
            {
                NSLog(@"Don't have an error to present for failing to save topography map");
            }
            
            [NSApp presentError:error];
        }
        else
        {
            self.fragmentShader = fileContents;
        }
    }
}

- (IBAction)saveVertexShader:(id)sender;
{
    NSSavePanel *shaderSavingDialog = [NSSavePanel savePanel];
    [shaderSavingDialog setAllowedFileTypes:[NSArray arrayWithObjects:@"vsh", @"txt", nil]];
    
    if ( [shaderSavingDialog runModal] == NSModalResponseOK )
    {
        NSError *error = nil;
        if (![self.vertexShader writeToURL:[shaderSavingDialog URL] atomically:NO encoding:NSASCIIStringEncoding error:&error])
        {
            if (error == nil)
            {
                NSLog(@"Don't have an error to present for failing to save topography map");
            }
            
            [NSApp presentError:error];
        }
    }
}

- (IBAction)saveFragmentShader:(id)sender;
{
    NSSavePanel *shaderSavingDialog = [NSSavePanel savePanel];
    [shaderSavingDialog setAllowedFileTypes:[NSArray arrayWithObjects:@"fsh", @"txt", nil]];
    
    if ( [shaderSavingDialog runModal] == NSModalResponseOK )
    {
        NSError *error = nil;
        if (![self.fragmentShader writeToURL:[shaderSavingDialog URL] atomically:NO encoding:NSASCIIStringEncoding error:&error])
        {
            if (error == nil)
            {
                NSLog(@"Don't have an error to present for failing to save topography map");
            }
            
            [NSApp presentError:error];
        }
    }
}

@end
