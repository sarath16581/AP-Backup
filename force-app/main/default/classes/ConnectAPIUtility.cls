/**
 *
 * Helper class that makes it easier to do common operations with the classes in the ConnectApi namespace.
 *
 * Includes convenience methods to:
 *
 *     - Post Chatter @-mentions, rich text, and inline images with Apex code.
 *     - Take a feed item or comment body and return an input body that matches it.
 *       This is useful for when you retrieve a feed item or comment and want to either
 *       re-post or edit it.
 *
 * This class works with API version 36.0 and later. There are separate classes
 * that work with v35.0 and earlier.
 *
 * See https://github.com/forcedotcom/ConnectApiHelper for more information.
 *
 * @author: rajesh.punjabi@mav3rik.com
 * @description: New Method added to accomdate live chat transcript feed item creation.
 * @description: method [createFeedItemforLiveChat]
 */

global class ConnectAPIUtility {

    public class InvalidParameterException extends Exception {}
    
    private static final Map<String, ConnectApi.MarkupType> supportedMarkup = new Map<String, ConnectApi.MarkupType> {
        'b' => ConnectApi.MarkupType.Bold, 
        'i' => ConnectApi.MarkupType.Italic, 
        'li' => ConnectApi.MarkupType.ListItem, 
        'ol' => ConnectApi.MarkupType.OrderedList, 
        'p' => ConnectApi.MarkupType.Paragraph, 
        's' => ConnectApi.MarkupType.Strikethrough, 
        'u' => ConnectApi.MarkupType.Underline, 
        'ul' => ConnectApi.MarkupType.UnorderedList
    };
    
    /**
     * Posts a feed item with special formatting and entity id.
     * 
     * @param CaseId The parent of the post. Can be a user ID, a group ID, or a record ID (mapped to Subject Id)
     * @param BodyText The feed item body content.
     * @param EntityId Linked Record Id.
     * @return The posted feed item.
     */
     
	public static void createFeedItemforLiveChat(Id CaseId, String BodyText, Id EntityId){
        //.. Linked Record (Entity Id)
        ConnectApi.EntityLinkSegmentInput entityLinkSegment = new ConnectApi.EntityLinkSegmentInput();
        entityLinkSegment.entityId = EntityId;
        
        //.. Feed Item MessageBody
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        
        //.. Message Segement (Body Text)
        messageBodyInput.messageSegments = getMessageSegmentInputs(BodyText);
        messageBodyInput.messageSegments.add(entityLinkSegment);
        
    	//.. Feed Item
		ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
		feedItemInput.body = messageBodyInput;
        
		feedItemInput.feedElementType =  ConnectApi.FeedElementType.FeedItem;	//.. Feed Element Type
		feedItemInput.subjectId = CaseId;

		ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(null, feedItemInput);
	}
   
    public static List<ConnectApi.MessageSegmentInput> getMessageSegmentInputs(String inputText) {
        if (inputText == null) {
            throw new InvalidParameterException('The inputText parameter cannot be null.');
        }

        List<ConnectApi.MessageSegmentInput> messageSegmentInputs = new List<ConnectApi.MessageSegmentInput>();
        Integer strPos = 0;
        // The pattern for matching mentions, markup begin/end tags, and inline images.
        // The first group matches a 15 or 18 character ID surrounded by {}: 
        //   (\\{[a-zA-Z0-9]{15}\\}|\\{[a-zA-Z0-9]{18}\\})
        // The second/third groups match beginning/ending HTML tags: (<[a-zA-Z]*>)|(</[a-zA-Z]*>)
        // The fourth group matches a 15 or 18 character content document ID preceded by "img:", 
        //    optionally followed by a string (not containing '}'), and surrounded by {}: 
        //    (\\{img:(069[a-zA-Z0-9]{12,15})(:[\\s\\S]*?)?\\})
        Pattern globalPattern = Pattern.compile('(\\{[a-zA-Z0-9]{15}\\}|\\{[a-zA-Z0-9]{18}\\})|(<[a-zA-Z]*>)|(</[a-zA-Z]*>)|(\\{img:(069[a-zA-Z0-9]{12,15})(:[\\s\\S]*?)?\\})');
        Matcher globalMatcher = globalPattern.matcher(inputText);
        
        while (globalMatcher.find()) {
            String textSegment = inputText.substring(strPos, globalMatcher.start());
            String matchingText = globalMatcher.group();
            if (matchingText.startsWith('{')) {
                // Add a segment for any accumulated text (which includes unsupported HTML tags).
                addTextSegment(messageSegmentInputs, textSegment); 

                // Strip off the { and }.
                String innerMatchedText = matchingText.substring(1, matchingText.length() - 1);

                if (innerMatchedText.startsWith('img:')) {
                    // This is an inline image.
                    String[] imageInfo = innerMatchedText.split(':', 3);
                    String altText = imageInfo.size() == 3 ? imageInfo[2] : null;
                    ConnectApi.InlineImageSegmentInput inlineImageSegmentInput = makeInlineImageSegmentInput(imageInfo[1], altText);
                    messageSegmentInputs.add(inlineImageSegmentInput);
                    strPos = globalMatcher.end();
                }
                else {
                    // This is a mention id.
                    ConnectApi.MentionSegmentInput mentionSegmentInput = makeMentionSegmentInput(innerMatchedText);
                    messageSegmentInputs.add(mentionSegmentInput);
                    strPos = globalMatcher.end();
                }
            }
            else {
                // This is an HTML tag.
                boolean isBeginTag = !matchingText.startsWith('</');
                if (isBeginTag) {
                    // Strip off the < and >.
                    String tag = matchingText.substring(1, matchingText.indexOf('>'));
                    if (supportedMarkup.containsKey(tag.toLowerCase())) {
                        // Add a segment for any accumulated text (which includes unsupported HTML tags).
                        addTextSegment(messageSegmentInputs, textSegment); 
                        
                        ConnectApi.MarkupBeginSegmentInput markupBeginSegmentInput = makeMarkupBeginSegmentInput(tag);
                        messageSegmentInputs.add(markupBeginSegmentInput);
                        strPos = globalMatcher.end();
                    }
                }
                else { // This is an end tag.
                    // Strip off the </ and >.
                    String tag = matchingText.substring(2, matchingText.indexOf('>'));
                    if (supportedMarkup.containsKey(tag.toLowerCase())) {
                        // Add a segment for any accumulated text (which includes unsupported HTML tags).
                        addTextSegment(messageSegmentInputs, textSegment); 

                        ConnectApi.MarkupEndSegmentInput markupEndSegmentInput = makeMarkupEndSegmentInput(tag);
                        messageSegmentInputs.add(markupEndSegmentInput);
                        strPos = globalMatcher.end();
                    }
                }
            }
        }

        // Take care of any text that comes after the last match.
        if (strPos < inputText.length()) {
            String trailingText = inputText.substring(strPos, inputText.length());
            addTextSegment(messageSegmentInputs, trailingText);
        }

        return messageSegmentInputs;
    }

    private static void addTextSegment(List<ConnectApi.MessageSegmentInput> messageSegmentInputs, String text) {
        if (text != null && text.length() > 0) {
            ConnectApi.TextSegmentInput textSegmentInput = makeTextSegmentInput(text);
            messageSegmentInputs.add(textSegmentInput);
        }
    }

    private static ConnectApi.TextSegmentInput makeTextSegmentInput(String text) {
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = text;
        return textSegment;
    }
    
    private static ConnectApi.MentionSegmentInput makeMentionSegmentInput(String mentionId) {
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        mentionSegment.id = mentionId;
        return mentionSegment;
    }
    
    /**
     * Create a MarkupBeginSegmentInput corresponding to the tag.  Checking whether the tag is 
     * supported markup should happen before calling this method.
     */
    private static ConnectApi.MarkupBeginSegmentInput makeMarkupBeginSegmentInput(String tag) {
        ConnectApi.MarkupBeginSegmentInput markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
        markupBeginSegment.markupType = supportedMarkup.get(tag.toLowerCase());
        return markupBeginSegment;
    }
    
    /**
     * Create a MarkupEndSegmentInput corresponding to the tag.  Checking whether the tag is 
     * supported markup should happen before calling this method.
     */
    private static ConnectApi.MarkupEndSegmentInput makeMarkupEndSegmentInput(String tag) {
        ConnectApi.MarkupEndSegmentInput markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
        markupEndSegment.markupType = supportedMarkup.get(tag.toLowerCase());
        return markupEndSegment;
    }
    
    private static ConnectApi.InlineImageSegmentInput makeInlineImageSegmentInput(String fileId, String altText) {
        ConnectApi.InlineImageSegmentInput inlineImageSegment = new ConnectApi.InlineImageSegmentInput();
        inlineImageSegment.fileId = fileId;
        if (String.isNotBlank(altText)) {
            inlineImageSegment.altText = altText;
        }
        return inlineImageSegment;
    }
    
    /**
     * Takes an output feed body and returns a message body input that matches it.
     * This is useful for when you retrieve a feed item or comment and want to either re-post or edit it.
     */
    public static ConnectApi.MessageBodyInput createInputFromBody(ConnectApi.FeedBody body) {
        ConnectApi.MessageBodyInput input = new ConnectApi.MessageBodyInput();
        input.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        for (ConnectApi.MessageSegment segment : body.messageSegments) {
            if (segment instanceof ConnectApi.TextSegment) {
                ConnectApi.TextSegment textOutput = (ConnectApi.TextSegment) segment;
                ConnectApi.TextSegmentInput textInput = new ConnectApi.TextSegmentInput();
                textInput.text = textOutput.text;
                input.messageSegments.add(textInput);
            }
            else if (segment instanceof ConnectApi.MentionSegment) {
                ConnectApi.MentionSegment mentionOutput = (ConnectApi.MentionSegment) segment;
                ConnectApi.MentionSegmentInput mentionInput = new ConnectApi.MentionSegmentInput();
                mentionInput.id = mentionOutput.record.id;
                input.messageSegments.add(mentionInput);
            }
            else if (segment instanceof ConnectApi.HashtagSegment) {
                ConnectApi.HashtagSegment hashtagOutput = (ConnectApi.HashtagSegment) segment;
                ConnectApi.HashtagSegmentInput hashtagInput = new ConnectApi.HashtagSegmentInput();
                hashtagInput.tag = hashtagOutput.tag;
                input.messageSegments.add(hashtagInput);
            }
            else if (segment instanceof ConnectApi.LinkSegment) {
                ConnectApi.LinkSegment linkOutput = (ConnectApi.LinkSegment) segment;
                ConnectApi.LinkSegmentInput linkInput = new ConnectApi.LinkSegmentInput();
                linkInput.url = linkOutput.url;
                input.messageSegments.add(linkInput);
            }
            else if (segment instanceof ConnectApi.MarkupBeginSegment) {
                ConnectApi.MarkupBeginSegment markupBeginOutput = (ConnectApi.MarkupBeginSegment) segment;
                ConnectApi.MarkupBeginSegmentInput markupBeginInput = new ConnectApi.MarkupBeginSegmentInput();
                markupBeginInput.markupType = markupBeginOutput.markupType;
                input.messageSegments.add(markupBeginInput);
            }
            else if (segment instanceof ConnectApi.MarkupEndSegment) {
                ConnectApi.MarkupEndSegment markupEndOutput = (ConnectApi.MarkupEndSegment) segment;
                ConnectApi.MarkupEndSegmentInput markupEndInput = new ConnectApi.MarkupEndSegmentInput();
                markupEndInput.markupType = markupEndOutput.markupType;
                input.messageSegments.add(markupEndInput);
            }
            else if (segment instanceof ConnectApi.InlineImageSegment) {
                ConnectApi.InlineImageSegment inlineImageOutput = (ConnectApi.InlineImageSegment) segment;
                ConnectApi.InlineImageSegmentInput inlineImageInput = new ConnectApi.InlineImageSegmentInput();
                inlineImageInput.fileId = inlineImageOutput.thumbnails.fileId;
                inlineImageInput.altText = inlineImageOutput.altText;
                input.messageSegments.add(inlineImageInput);
            }
            else {
                // The other segment types are system-generated and have no corresponding input types.
            }
            
        }
        return input;
    }
    
    /**
     * Takes an output body and returns a feed item input body that matches it.
     * This is useful for when you retrieve a feed item and want to either re-post or edit it.
     */
    public static ConnectApi.FeedItemInput createFeedItemInputFromBody(ConnectApi.FeedBody body) {
        ConnectApi.MessageBodyInput bodyInput = createInputFromBody(body);
        
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = bodyInput;
        return input;
    }
    
    /**
     * Takes an output body and returns a comment input body that matches it.
     * This is useful for when you retrieve a comment and want to either re-post or edit it.
     */
    public static ConnectApi.CommentInput createCommentInputFromBody(ConnectApi.FeedBody body) {
        ConnectApi.MessageBodyInput bodyInput = createInputFromBody(body);
        
        ConnectApi.CommentInput input = new ConnectApi.CommentInput();
        input.body = bodyInput;
        return input;
    }
}