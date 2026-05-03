import Foundation

class RSSParser: NSObject, XMLParserDelegate {
    
    private var items: [(title: String, link: String, pubDate: String, description: String, source: String)] = []
    
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentDescription = ""
    private var currentSource = ""
    
    func parse(data: Data) -> [(title: String, link: String, pubDate: String, description: String, source: String)] {
        items = []
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        
        return items
    }
    
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title":
            currentTitle += string
        case "link":
            currentLink += string
        case "pubDate":
            currentPubDate += string
        case "description":
            currentDescription += string
        case "source":
            currentSource += string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser,
                didEndElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?) {
        
        if elementName == "item" {
            let cleanedDescription = currentDescription
                .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let cleanedSource = currentSource
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            items.append((
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines),
                description: cleanedDescription,
                source: cleanedSource
            ))
            
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""
            currentDescription = ""
            currentSource = ""
        }
    }
}
