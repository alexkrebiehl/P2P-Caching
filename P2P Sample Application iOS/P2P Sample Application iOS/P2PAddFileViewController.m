//
//  P2PAddFileViewController.m
//  P2P Sample Application iOS
//
//  Created by Alex Krebiehl on 3/17/14.
//  Copyright (c) 2014 NKU Research. All rights reserved.
//

#import "P2PAddFileViewController.h"

@interface P2PAddFileViewController () <UIAlertViewDelegate, UITextFieldDelegate>

@end

@implementation P2PAddFileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Request File";
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.filenameLabel becomeFirstResponder];
    self.filenameLabel.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)getFileButtonPressed:(id)sender
{
    if ( [self.filenameLabel.text isEqualToString:@""] )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Invalid filename"
                                                        message:@"Enter a file name"
                                                       delegate:self
                                              cancelButtonTitle:@"ok"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        [self.delegate addFileController:self didSelectFileToAdd:self.filenameLabel.text];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self getFileButtonPressed:textField];
    
    return YES;
}

@end
