import Foundation

protocol HomeViewModelDelegate: AnyObject {
    func didUpdateRoutes()
    func didUpdateUserInfo()
    func didFailWithError(_ error: Error)
}

class HomeViewModel {
    
    // MARK: - Properties
    
    weak var delegate: HomeViewModelDelegate?
    
    private(set) var routes: [Route] = [] {
        didSet {
            manageRouteData()
            delegate?.didUpdateRoutes()
        }
    }
    
    private(set) var userOne: [Route] = []
    private(set) var recommendOne: [Route] = []
    private(set) var riverOne: [Route] = []
    private(set) var mountainOne: [Route] = []
    
    private let mapsManager: MapsManager
    private let userManager: UserManager
    
    // MARK: - Initialization
    
    init(mapsManager: MapsManager = .shared, userManager: UserManager = .shared) {
        self.mapsManager = mapsManager
        self.userManager = userManager
    }
    
    // MARK: - Public Methods
    
    func fetchTrailData() {
        mapsManager.fetchRoutes { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let routes):
                let filteredRoutes = routes.filter { route in
                    !(self.userManager.userInfo.blockList?.contains(route.uid ?? "") ?? false)
                }
                self.routes = filteredRoutes
                
            case .failure(let error):
                self.delegate?.didFailWithError(error)
            }
        }
    }
    
    func updateUserInfo() {
        delegate?.didUpdateUserInfo()
    }
    
    func getRoutesForType(_ type: Int) -> [Route] {
        switch type {
        case 0: return userOne
        case 1: return recommendOne
        case 2: return riverOne
        case 3: return mountainOne
        default: return []
        }
    }
    
    // MARK: - Private Methods
    
    private func manageRouteData() {
        userOne = []
        recommendOne = []
        riverOne = []
        mountainOne = []
        
        for route in routes {
            switch route.routeTypes {
            case 0: userOne.append(route)
            case 1: recommendOne.append(route)
            case 2: riverOne.append(route)
            case 3: mountainOne.append(route)
            default: break
            }
        }
    }
} 