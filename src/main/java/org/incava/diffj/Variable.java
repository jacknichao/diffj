package org.incava.diffj;

import java.util.List;
import net.sourceforge.pmd.ast.ASTType;
import net.sourceforge.pmd.ast.ASTVariableDeclarator;
import net.sourceforge.pmd.ast.ASTVariableInitializer;
import net.sourceforge.pmd.ast.SimpleNode;
import net.sourceforge.pmd.ast.Token;
import org.incava.pmdx.FieldUtil;
import org.incava.pmdx.SimpleNodeUtil;

/**
 * A list of variables within a type, such as:
 *
 * <pre>
 *     String s = "foo", t = "bar", u = null;
 * </pre>
 */
public class Variable extends Item {
    private final ASTType type;
    private final ASTVariableDeclarator variable;
    private final ASTVariableInitializer init;

    public Variable(ASTType type, ASTVariableDeclarator variable) {
        super(variable);
        
        this.type = type;
        this.variable = variable;
        this.init = (ASTVariableInitializer)SimpleNodeUtil.findChild(variable, "net.sourceforge.pmd.ast.ASTVariableInitializer");;
    }

    public void diff(Variable toVariable, Differences differences) {
        String fromTypeStr = getTypeName();
        String toTypeStr = toVariable.getTypeName();

        if (!fromTypeStr.equals(toTypeStr)) {
            String name = getName();
            differences.changed(type, toVariable.type, Messages.VARIABLE_TYPE_CHANGED, name, fromTypeStr, toTypeStr);
        }

        compareVariableInits(toVariable, differences);
    }

    public String getName() {
        return FieldUtil.getName(variable).image;
    }

    public ASTVariableInitializer getInitializer() {
        return init;
    }

    public boolean hasInitializer() {
        return init != null;
    }

    public List<Token> getCodeTokens() {
        return SimpleNodeUtil.getChildTokens(init);
    }
    
    public String getTypeName() {
        return SimpleNodeUtil.toString(type);
    }

    protected void compareInitCode(Variable toVariable, Differences differences) {
        String      fromName = getName();
        List<Token> fromCode = getCodeTokens();
        List<Token> toCode   = toVariable.getCodeTokens();
        
        // It is logically impossible for this to execute where "to"
        // represents the from-file, and "from" the to-file, since "from.name"
        // would have matched "to.name" in the first loop of
        // compareVariableLists
        
        compareCode(fromName, fromCode, toCode, differences);
    }

    protected void compareVariableInits(Variable toVariable, Differences differences) {
        ASTVariableInitializer fromInit = getInitializer();
        ASTVariableInitializer toInit = toVariable.getInitializer();

        if (hasInitializer()) {
            if (toVariable.hasInitializer()) {
                compareInitCode(toVariable, differences);
            }
            else {
                differences.changed(init, toVariable.variable, Messages.INITIALIZER_REMOVED);
            }
        }
        else if (toVariable.hasInitializer()) {
            differences.changed(variable, toVariable.getInitializer(), Messages.INITIALIZER_ADDED);
        }
    }
}
