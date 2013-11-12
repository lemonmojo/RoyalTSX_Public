#import "RdpViewLibrary.h"
#import "remojoRdesktopController.h"

NSObject* getRdpViewController(id parentController, NSWindow* mainWindow) {
    return [[remojoRdesktopController alloc] initWithParentController:parentController andMainWindow:mainWindow];
}