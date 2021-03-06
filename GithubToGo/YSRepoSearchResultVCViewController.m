//
//  YSRepoSearchResultVCViewController.m
//  GithubToGo
//
//  Created by Yair Szarf on 1/28/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import "YSRepoSearchResultVCViewController.h"
#import "YSDetailViewController.h"
#import "YSGithubNetworkController.h"
#import "Repo.h"
#import "YSAppDelegate.h"


@interface YSRepoSearchResultVCViewController ()

@property (strong, nonatomic) NSArray * searchResultsArray;
@property (strong, nonatomic) YSGithubNetworkController * sharedNetworkController;
@property BOOL menuIsOut;
@property (weak, nonatomic) IBOutlet UISearchBar * searchBar;



@end

@implementation YSRepoSearchResultVCViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    YSAppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    self.detailViewController = (YSDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    self.sharedNetworkController = [YSGithubNetworkController sharedNetworkController];
    

}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.clearsSelectionOnViewWillAppear) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    self.view.frame = self.parentViewController.view.frame;
}



- (void) searchReposForString:(NSString *) string {
    self.searchResultsArray = [self.sharedNetworkController searchReposForString:string];
    [self parseReposArrayToMObjects:self.searchResultsArray];
    
    [self.tableView reloadData];
}

-  (void)parseReposArrayToMObjects:(NSArray *) repos {
    for (NSDictionary * repoDict in repos) {
        NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"Repo" inManagedObjectContext:self.managedObjectContext];
        Repo * repo = [[Repo alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext withJSONDict:repoDict];
        
        [repo.managedObjectContext save:nil];
    }
}

- (NSFetchedResultsController *) fetchedRestultsController
{
    if (_fetchedRestultsController != nil) {
        return _fetchedRestultsController;
    }
    NSFetchRequest * fetchRequest = [NSFetchRequest new];
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"Repo" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entityDescription];
    fetchRequest.fetchBatchSize = 25;
    NSSortDescriptor * sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    self.fetchedRestultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Repo"];
    [self.fetchedRestultsController performFetch:nil];
    return _fetchedRestultsController;
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedRestultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    Repo * repo = [self.fetchedRestultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = repo.name;
    cell.detailTextLabel.text = repo.html_url;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Repo * repo = [self.fetchedRestultsController objectAtIndexPath:indexPath];
    self.detailViewController.detailItem = repo;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [self performSegueWithIdentifier:@"showDetail" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Repo * repo = [self.fetchedRestultsController objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:repo];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self searchReposForString:searchBar.text];
    
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self clearSearchResults];
    [searchBar resignFirstResponder];
    
    [self searchReposForString:searchBar.text];
}

- (void) clearSearchResults
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedRestultsController sections][0];
    NSInteger  forCount = [sectionInfo numberOfObjects];
    for (NSInteger i = 0; i < forCount; i ++) {
        NSIndexPath * indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        Repo * repo = [self.fetchedRestultsController objectAtIndexPath:indexPath];
        NSLog(@"%@",repo);
        [self.managedObjectContext deleteObject:repo];
        
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    //This is a gist by @johnnyclem https://gist.github.com/johnnyclem/8215415 well done!
    for (UIControl *control in self.view.subviews) {
        if ([control isKindOfClass:[UISearchBar class]]) {
            [control resignFirstResponder];
        }
    }
}


@end
